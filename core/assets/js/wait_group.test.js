import { describe, it, expect } from "vitest";
import { WaitGroup } from "./wait_group";

describe("WaitGroup", () => {
  it("resolves immediately when count is zero", async () => {
    const wg = new WaitGroup();
    await wg.wait();
    expect(wg.count).toBe(0);
  });

  it("waits for all operations to complete", async () => {
    const wg = new WaitGroup();
    const order = [];

    wg.add();
    wg.add();

    const waitPromise = wg.wait().then(() => order.push("wait"));

    // Simulate async operations
    setTimeout(() => {
      order.push("done1");
      wg.done();
    }, 10);

    setTimeout(() => {
      order.push("done2");
      wg.done();
    }, 20);

    await waitPromise;

    expect(order).toEqual(["done1", "done2", "wait"]);
  });

  it("tracks count correctly with add and done", () => {
    const wg = new WaitGroup();
    expect(wg.count).toBe(0);

    wg.add();
    expect(wg.count).toBe(1);

    wg.add();
    expect(wg.count).toBe(2);

    wg.done();
    expect(wg.count).toBe(1);

    wg.done();
    expect(wg.count).toBe(0);
  });
});
