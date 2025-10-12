import chalk from 'chalk';
import ora from 'ora';

type SpinnerStore = {
  current: ReturnType<typeof ora> | null;
};

const spinnerStore: SpinnerStore = {
  current: null
};

export function logHeader(message: string): void {
  console.log(chalk.bold.blue(`\n=== ${message} ===\n`));
}

export function logStep(message: string): void {
  // Stop any existing spinner
  if (spinnerStore.current) {
    spinnerStore.current.stop();
  }
  
  // Start a new spinner
  spinnerStore.current = ora({
    text: chalk.yellow(message + '...'),
    spinner: 'dots'
  }).start();
}

export function logStepComplete(message: string): void {
  if (spinnerStore.current) {
    spinnerStore.current.succeed(chalk.green(message));
    spinnerStore.current = null;
  } else {
    console.log(chalk.green('✓ ' + message));
  }
}

export function logStepFailed(message: string): void {
  if (spinnerStore.current) {
    spinnerStore.current.fail(chalk.red(message));
    spinnerStore.current = null;
  } else {
    console.log(chalk.red('✗ ' + message));
  }
}

export function logInfo(message: string): void {
  // More compact info logging
  if (spinnerStore.current) {
    // Temporarily pause the spinner to show info inline
    const text = spinnerStore.current.text;
    spinnerStore.current.text = chalk.blue(`ℹ ${message}`);
    setTimeout(() => {
      if (spinnerStore.current) {
        spinnerStore.current.text = text;
      }
    }, 1500); // Show info message briefly then restore spinner
  } else {
    console.log(chalk.blue(`ℹ ${message}`));
  }
}

export function logSuccess(message: string): void {
  // More compact success message on a single line
  console.log('\n' + chalk.bold.green(`✅ ${message} ✅`) + '\n');
}

export function logWarning(message: string): void {
  console.log(chalk.yellow('⚠ ' + message));
}

export function logError(message: string): void {
  console.log(chalk.bold.red(`\n❌ ERROR: ${message}\n`));
}
