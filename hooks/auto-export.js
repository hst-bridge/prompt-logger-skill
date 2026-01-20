#!/usr/bin/env node
// Auto-export transcript to markdown on session end

const fs = require('fs');
const path = require('path');

// Read hook input from stdin
let inputData = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => inputData += chunk);
process.stdin.on('end', () => {
    try {
        const data = JSON.parse(inputData);
        const transcriptPath = data.transcript_path;
        const cwd = data.cwd || process.cwd();

        if (!transcriptPath || !fs.existsSync(transcriptPath)) {
            process.exit(0);
        }

        // Generate output filename with timestamp (same as Mac format)
        const now = new Date();
        const timestamp = now.toISOString().replace(/[-:]/g, '').replace('T', '_').substring(0, 15);
        const outputFile = path.join(cwd, `claude_prompt-history-${timestamp}.md`);

        // Convert transcript
        convertTranscript(transcriptPath, outputFile);

    } catch (e) {
        // Silent fail
    }
    process.exit(0);
});

function formatTimestamp(isoString) {
    if (!isoString) return '';
    const date = new Date(isoString);
    return date.toLocaleString('zh-CN', {
        year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false
    });
}

function extractTextContent(content) {
    if (!content) return '';
    if (typeof content === 'string') return content;
    if (Array.isArray(content)) {
        return content.filter(b => b.type === 'text').map(b => b.text || '').join('\n');
    }
    return '';
}

function convertTranscript(inputFile, outputFile) {
    const content = fs.readFileSync(inputFile, 'utf8');
    const lines = content.split('\n').filter(l => l.trim());

    let markdown = '';
    let sessionInfo = null;
    let processedMessages = new Set();

    // Get session info
    for (const line of lines) {
        try {
            const entry = JSON.parse(line);
            if (entry.type === 'user' && entry.sessionId && !sessionInfo) {
                sessionInfo = { sessionId: entry.sessionId, cwd: entry.cwd, version: entry.version, timestamp: entry.timestamp };
                break;
            }
        } catch (e) { continue; }
    }

    // Header
    markdown += `# Claude Code 对话记录\n\n`;
    if (sessionInfo) {
        markdown += `**Session ID**: ${sessionInfo.sessionId}\n`;
        markdown += `**工作目录**: ${sessionInfo.cwd}\n`;
        markdown += `**版本**: ${sessionInfo.version}\n`;
        markdown += `**时间**: ${formatTimestamp(sessionInfo.timestamp)}\n`;
    }
    markdown += `\n---\n\n`;

    // Extract conversations
    for (const line of lines) {
        try {
            const entry = JSON.parse(line);

            // User message
            if (entry.type === 'user' && entry.message?.role === 'user') {
                const content = entry.message.content;
                if (Array.isArray(content) && content[0]?.type === 'tool_result') continue;

                const messageId = entry.uuid;
                if (processedMessages.has(messageId)) continue;
                processedMessages.add(messageId);

                const text = typeof content === 'string' ? content : extractTextContent(content);
                if (text?.trim()) {
                    markdown += `## User (${formatTimestamp(entry.timestamp)})\n\n${text}\n\n`;
                }
            }

            // Assistant message
            if (entry.type === 'assistant' && entry.message?.role === 'assistant') {
                const text = extractTextContent(entry.message.content);
                if (text?.trim()) {
                    const messageId = entry.uuid;
                    if (processedMessages.has(messageId)) continue;
                    processedMessages.add(messageId);
                    markdown += `## Claude (${formatTimestamp(entry.timestamp)})\n\n${text}\n\n`;
                }
            }
        } catch (e) { continue; }
    }

    fs.writeFileSync(outputFile, markdown, 'utf8');
}
