const fs = require('fs');
const csv = require('csv-parser');

const rows = [];

fs.createReadStream('jacks_or_better_9_6_standard.csv')
  .pipe(csv())
  .on('data', (row) => {
    rows.push(row);
  })
  .on('end', () => {
    // J only blocks from the previous output
    const blocks = [
      { start: 169836, end: 169868 },
      { start: 169943, end: 170047 },
      { start: 170112, end: 170231 },
      { start: 171653, end: 172184 },
      { start: 173002, end: 173126 },
      { start: 173476, end: 173817 },
      { start: 174077, end: 174410 },
      { start: 174657, end: 174829 },
      { start: 174950, end: 175069 },
      { start: 175080, end: 175333 },
      { start: 175506, end: 175548 },
      { start: 176020, end: 176212 },
      { start: 176375, end: 176628 },
      { start: 177068, end: 177114 },
      { start: 182882, end: 183077 }
    ];

    console.log('What appears BETWEEN blocks of "J only":\n');

    for (let i = 0; i < Math.min(blocks.length - 1, 10); i++) {
      const gapStart = blocks[i].end + 1;
      const gapEnd = blocks[i + 1].start - 1;

      if (gapEnd >= gapStart) {
        console.log(`Between block ${i + 1} and block ${i + 2} (rows ${gapStart}-${gapEnd}):`);

        // Get unique descriptions in this gap
        const descsInGap = new Set();
        for (let rowIdx = gapStart - 1; rowIdx < gapEnd && rowIdx < rows.length; rowIdx++) {
          descsInGap.add(rows[rowIdx].description);
        }

        const sortedDescs = Array.from(descsInGap).sort();
        sortedDescs.forEach(desc => {
          console.log(`  ${desc}`);
        });

        // Show a sample row
        if (gapStart - 1 < rows.length) {
          const sampleRow = rows[gapStart - 1];
          console.log(`  Example: ${sampleRow.hand_key} = ${sampleRow.description} (EV=${sampleRow.best_ev})`);
        }
        console.log();
      }
    }
  });
