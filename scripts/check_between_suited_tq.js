const fs = require('fs');
const csv = require('csv-parser');

const rows = [];

fs.createReadStream('jacks_or_better_9_6_standard.csv')
  .pipe(csv())
  .on('data', (row) => {
    rows.push(row);
  })
  .on('end', () => {
    // Suited TQ blocks from the previous output
    const blocks = [
      { start: 165361, end: 165450 },
      { start: 168160, end: 168231 },
      { start: 169869, end: 169942 },
      { start: 170277, end: 170369 },
      { start: 173818, end: 173847 },
      { start: 174830, end: 174949 },
      { start: 176629, end: 176658 },
      { start: 184639, end: 184698 },
      { start: 185048, end: 185052 },
      { start: 191671, end: 191730 },
      { start: 194931, end: 194940 }
    ];

    console.log('What appears BETWEEN blocks of "Suited TQ":\n');

    for (let i = 0; i < blocks.length - 1; i++) {
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
