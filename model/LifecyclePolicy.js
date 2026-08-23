function createOwnerState() {
  return {alive: true, generation: 0};
}

function captureGeneration(owner) {
  return owner && typeof owner.generation === "number" ? owner.generation : -1;
}

function canRun(owner, generation) {
  return !!owner && owner.alive === true
    && owner.generation === generation;
}

function invalidate(owner) {
  if (!owner || owner.alive !== true) return false;
  owner.alive = false;
  owner.generation += 1;
  return true;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    createOwnerState: createOwnerState,
    captureGeneration: captureGeneration,
    canRun: canRun,
    invalidate: invalidate
  };
}
