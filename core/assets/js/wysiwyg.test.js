import { afterEach, describe, expect, it, vi } from "vitest";

vi.mock("trix", () => ({ default: {} }));

const { Wysiwyg } = await import("./wysiwyg");

function mountHook(attachments) {
  const el = document.createElement("div");
  el.dataset.id = "body_input";
  el.dataset.name = "announcement[body]_input";
  el.dataset.html = "";
  el.dataset.visible = "true";
  el.dataset.attachments = attachments;
  document.body.appendChild(el);

  const hook = Object.create(Wysiwyg);
  hook.el = el;
  hook.mounted();
  return hook;
}

function fileAccept(editor) {
  const event = new Event("trix-file-accept", { cancelable: true });
  editor.dispatchEvent(event);
  return event;
}

function attachmentAdd(editor) {
  const attachment = { remove: vi.fn() };
  const event = new Event("trix-attachment-add");
  event.attachment = attachment;
  editor.dispatchEvent(event);
  return attachment;
}

describe("Wysiwyg", () => {
  afterEach(() => {
    document.body.innerHTML = "";
    vi.restoreAllMocks();
  });

  describe("with attachments off", () => {
    it("refuses files", () => {
      vi.spyOn(console, "log").mockImplementation(() => {});
      const { editor } = mountHook("false");

      expect(fileAccept(editor).defaultPrevented).toBe(true);
    });

    it("removes every added attachment", () => {
      vi.spyOn(console, "log").mockImplementation(() => {});
      const { editor } = mountHook("false");

      expect(attachmentAdd(editor).remove).toHaveBeenCalledOnce();
    });
  });

  describe("with attachments on", () => {
    it("accepts files and keeps attachments", () => {
      vi.spyOn(console, "log").mockImplementation(() => {});
      const { editor } = mountHook("true");

      expect(fileAccept(editor).defaultPrevented).toBe(false);
      expect(attachmentAdd(editor).remove).not.toHaveBeenCalled();
    });
  });
});
