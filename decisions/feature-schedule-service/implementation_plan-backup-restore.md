# Implementation Plan: Schedule Backup and Restore Commands

We want to add `/schedule backup` and `/schedule restore` slash commands to LazyGravity. This will allow operators to easily export and import their recurring cron task schedules.

## Design Concept

To provide a premium operator experience, we will use Discord's native attachment capabilities:
1. **`/schedule backup`**: Serializes all schedules from SQLite to JSON, formats it as an attachment, and replies with the file (`schedules_backup.json`) directly in Discord.
2. **`/schedule restore <attachment>`**: Receives a JSON backup file as a Discord attachment option, downloads and validates it, stops all running cron tasks, clears the database table, imports the saved schedules, and registers/resumes them in memory.

---

## Proposed Changes

### 1. Slash Command Registration
#### [MODIFY] [registerSlashCommands.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/commands/registerSlashCommands.ts)
Add two new subcommands to the `schedule` command builder:
- `backup`: No options required.
- `restore`: Adds an attachment option `file` (required).

```typescript
    .addSubcommand((sub) =>
        sub
            .setName('backup')
            .setDescription(t('Export all scheduled tasks as a JSON file attachment'))
    )
    .addSubcommand((sub) =>
        sub
            .setName('restore')
            .setDescription(t('Restore scheduled tasks from a JSON file attachment'))
            .addAttachmentOption((option) =>
                option
                    .setName('file')
                    .setDescription(t('The schedules_backup.json file to import'))
                    .setRequired(true)
            )
    )
```

---

### 2. Database Layer
#### [MODIFY] [scheduleRepository.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/database/scheduleRepository.ts)
Add bulk import capabilities. We want to execute this in a single database transaction for safety:

```typescript
    /**
     * Bulk restore schedules. Clears the table and inserts all provided records.
     */
    public bulkRestore(records: Array<{ cronExpression: string; prompt: string; workspacePath: string; enabled: boolean }>): ScheduleRecord[] {
        const result: ScheduleRecord[] = [];
        this.db.transaction(() => {
            this.reset();
            const stmt = this.db.prepare(`
                INSERT INTO schedules (cron_expression, prompt, workspace_path, enabled)
                VALUES (?, ?, ?, ?)
            `);
            for (const record of records) {
                const insertResult = stmt.run(
                    record.cronExpression,
                    record.prompt,
                    record.workspacePath,
                    record.enabled ? 1 : 0
                );
                result.push({
                    id: insertResult.lastInsertRowid as number,
                    cronExpression: record.cronExpression,
                    prompt: record.prompt,
                    workspacePath: record.workspacePath,
                    enabled: record.enabled,
                });
            }
        })();
        return result;
    }
```

---

### 3. Service Layer
#### [MODIFY] [scheduleService.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/services/scheduleService.ts)
Add backup serialization and restore restoration:

```typescript
    /**
     * Export all schedules as a JSON string
     */
    public backupSchedules(): string {
        const list = this.listSchedules();
        // Export only portable fields (exclude autoincrement ID and timestamps)
        const portable = list.map(s => ({
            cronExpression: s.cronExpression,
            prompt: s.prompt,
            workspacePath: s.workspacePath,
            enabled: s.enabled
        }));
        return JSON.stringify(portable, null, 2);
    }

    /**
     * Restore schedules from JSON content
     */
    public restoreSchedules(jsonContent: string, jobCallback: JobCallback): number {
        const parsed = JSON.parse(jsonContent);
        if (!Array.isArray(parsed)) {
            throw new Error('Invalid backup format: root must be an array of schedule objects.');
        }

        // Validate items
        const validated: Array<{ cronExpression: string; prompt: string; workspacePath: string; enabled: boolean }> = [];
        for (const item of parsed) {
            if (typeof item.cronExpression !== 'string' || typeof item.prompt !== 'string' || typeof item.workspacePath !== 'string') {
                throw new Error('Invalid backup format: each schedule must contain cronExpression, prompt, and workspacePath.');
            }
            if (!cron.validate(item.cronExpression)) {
                throw new Error(`Invalid cron expression in backup: "${item.cronExpression}"`);
            }
            validated.push({
                cronExpression: item.cronExpression,
                prompt: item.prompt,
                workspacePath: item.workspacePath,
                enabled: typeof item.enabled === 'boolean' ? item.enabled : true
            });
        }

        // Stop memory crons
        this.stopAll();

        // Write to DB
        const restoredRecords = this.repo.bulkRestore(validated);

        // Resume crons in memory
        for (const record of restoredRecords) {
            if (record.enabled) {
                this.registerCronTask(record, jobCallback);
            }
        }

        return restoredRecords.length;
    }
```

---

### 4. Slash Command Routing
#### [MODIFY] [index.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/bot/index.ts)
Handle the subcommands in the interaction handler. We will download the attachment content via standard Node.js `https` module or `axios`:

```typescript
            if (subcommand === 'backup') {
                const json = scheduleService.backupSchedules();
                const buffer = Buffer.from(json, 'utf-8');
                await interaction.editReply({
                    content: '📋 **LazyGravity Schedules Backup**',
                    files: [{
                        attachment: buffer,
                        name: 'schedules_backup.json'
                    }]
                });
                break;
            }

            if (subcommand === 'restore') {
                const attachment = interaction.options.getAttachment('file', true);
                if (!attachment.name.endsWith('.json')) {
                    await interaction.editReply({ content: '❌ Attachment must be a `.json` file.' });
                    break;
                }

                try {
                    // Download file content
                    const response = await fetch(attachment.url);
                    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                    const jsonText = await response.text();

                    const jobCb = (_client as any).scheduleJobCallback || (async () => {});
                    const restoredCount = scheduleService.restoreSchedules(jsonText, jobCb);

                    await interaction.editReply({ content: `✅ Successfully restored ${restoredCount} scheduled tasks from backup!` });
                } catch (error: any) {
                    await interaction.editReply({ content: `❌ Failed to restore schedules: ${error.message}` });
                }
                break;
            }
```

---

## Verification Plan

### Automated Unit Tests
We will add unit test suites to:
- `tests/services/scheduleService.test.ts` to test schema validation, backup serialization, and transactional restore.

### Manual Verification
1. Add multiple scheduled tasks via `/schedule add`.
2. Execute `/schedule backup` and save the downloaded file.
3. Clear schedules via `/schedule clear`.
4. Verify `/schedule list` shows no schedules.
5. Execute `/schedule restore` uploading the saved JSON backup file.
6. Verify `/schedule list` displays the restored schedules with correct next-run times.
