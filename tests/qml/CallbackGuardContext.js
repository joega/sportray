.pragma library

// A disposed QML import namespace can no longer be dereferenced. Model that
// boundary deterministically: cancellation must reject the captured plain owner
// before it asks this context for anything.
function createOwnerState() { return {alive: true, generation: 0}; }
function captureGeneration(owner) { return owner.generation; }
function canRun(owner, generation) {
  if (!owner.alive || owner.generation !== generation)
    throw new Error("A canceled callback accessed its disposed context");
  return true;
}
