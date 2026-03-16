import { readFile } from "node:fs/promises";

// Configure memory
const mem = new WebAssembly.Memory({ initial: 10 });
const memView = new Uint8Array(mem.buffer);

// Create debug log method
function log(off: number, len: number) {
    const bytes = new Uint8Array(mem.buffer, off, len);
    const str = new TextDecoder("utf-8").decode(bytes);
    console.log(`[${off} for ${len}]=${str}`);
}

function logx(value: number) {
    console.log("(", value, ")");
}

// Load and compile the wasm
const moduleBytes = await readFile("./solve.wasm");
const module = new WebAssembly.Module(moduleBytes);
const instance = new WebAssembly.Instance(module, {
    js: {
        mem,
        log,
        logx,
    },
});

// Read the input file as bytes
const input = await readFile("./input.txt", "utf-8");
const inputBytes = Buffer.from(input, "ascii");

// Write the input to WASM memory
const offset = 0;
const len = inputBytes.length;
memView.set(inputBytes, offset);

// Run the solve
const out = instance.exports.solve(offset, len);
console.log("->", out);
