import chalk from 'chalk';

export enum TestStatus {
  PASSED = 'PASSED',
  FAILED = 'FAILED',
  SKIPPED = 'SKIPPED',
}

export class TestReporter {
  private testResults: { name: string; status: TestStatus; message?: string }[] = [];

  public addResult(name: string, status: TestStatus, message?: string): void {
    this.testResults.push({ name, status, message });
  }

  public printSummary(): void {
    console.log('\n');
    console.log('='.repeat(80));
    console.log(chalk.bold('TEST SUMMARY:'));
    console.log('='.repeat(80));
    
    let passed = 0;
    let failed = 0;
    let skipped = 0;

    this.testResults.forEach((result, index) => {
      let statusColor;
      switch (result.status) {
        case TestStatus.PASSED:
          statusColor = chalk.green;
          passed++;
          break;
        case TestStatus.FAILED:
          statusColor = chalk.red;
          failed++;
          break;
        case TestStatus.SKIPPED:
          statusColor = chalk.yellow;
          skipped++;
          break;
      }

      console.log(`${index + 1}. ${result.name}: ${statusColor(result.status)}`);
      if (result.message) {
        console.log(`   ${result.message}`);
      }
    });

    console.log('-'.repeat(80));
    console.log(chalk.bold(`Total: ${this.testResults.length} | Passed: ${chalk.green(passed)} | Failed: ${chalk.red(failed)} | Skipped: ${chalk.yellow(skipped)}`));
    console.log('='.repeat(80));

    if (failed > 0) {
      process.exit(1);
    }
  }
}