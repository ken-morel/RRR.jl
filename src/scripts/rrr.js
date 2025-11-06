const readline = require('readline');
const vm = require('vm');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

// The context object for the VM, to maintain state.
const context = vm.createContext({ console });

async function main() {
  let lines = [];
  for await (const line of rl) {
    lines.push(line);
  }

  let i = 0;
  while (i < lines.length) {
    const sentinel = lines[i];
    if (!sentinel) break;
    i++;

    let code_to_run = '';
    while (i < lines.length && lines[i] !== sentinel) {
      code_to_run += lines[i] + '\n';
      i++;
    }
    i++; // Move past the closing sentinel

    try {
      vm.runInContext(code_to_run, context);
    } catch (e) {
      console.error(e.stack);
    }

    console.log(sentinel);
  }
}

main();

