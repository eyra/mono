// WaitGroup pattern for tracking in-flight async operations
// Inspired by Go's sync.WaitGroup
export class WaitGroup {
  constructor() {
    this.count = 0;
    this.resolvers = [];
  }

  add() {
    this.count++;
  }

  done() {
    this.count--;
    if (this.count === 0) {
      this.resolvers.forEach((resolve) => resolve());
      this.resolvers = [];
    }
  }

  wait() {
    if (this.count === 0) {
      return Promise.resolve();
    }
    return new Promise((resolve) => {
      this.resolvers.push(resolve);
    });
  }
}
