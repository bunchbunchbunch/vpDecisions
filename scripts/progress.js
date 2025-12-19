// Check calculation progress for all paytables
import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

config({ path: join(__dirname, '..', '.env') });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
const TOTAL_HANDS = 204087;

async function checkProgress() {
    // Get counts grouped by paytable
    const { data, error } = await supabase
        .from('strategy')
        .select('paytable_id');

    if (error) {
        console.error('Error:', error.message);
        return;
    }

    // Count by paytable
    const counts = {};
    data.forEach(row => {
        counts[row.paytable_id] = (counts[row.paytable_id] || 0) + 1;
    });

    console.log('\n╔══════════════════════════════════════════════════════════════╗');
    console.log('║                    PAYTABLE PROGRESS                         ║');
    console.log('╠══════════════════════════════════════════════════════════════╣');

    if (Object.keys(counts).length === 0) {
        console.log('║  No data yet                                                 ║');
    } else {
        Object.entries(counts).sort().forEach(([id, count]) => {
            const pct = ((count / TOTAL_HANDS) * 100).toFixed(2);
            const barWidth = 20;
            const filled = Math.floor((count / TOTAL_HANDS) * barWidth);
            const bar = '█'.repeat(filled) + '░'.repeat(barWidth - filled);

            console.log(`║  ${id.padEnd(30)}`);
            console.log(`║  [${bar}] ${pct.padStart(6)}%  (${count.toLocaleString().padStart(7)} / ${TOTAL_HANDS.toLocaleString()}) ║`);
        });
    }

    console.log('╚══════════════════════════════════════════════════════════════╝\n');

    // Also show total
    const total = Object.values(counts).reduce((a, b) => a + b, 0);
    console.log(`Total rows in database: ${total.toLocaleString()}`);
}

checkProgress();
