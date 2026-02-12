const Sqids = require("sqids").default;

// Same alphabet as used in Elixir Systems.Affiliate.Sqids
const sqids = new Sqids({
  minLength: 6,
  alphabet: "ib09gZ5ICaXJKHtLAvu6Rj4yGwsofN1p8nxWeFQYVcBz7lkqP23dTSErMODmhU",
});

// annotation_resource_id is 0 for assignments
const ANNOTATION_RESOURCE_ID = 0;

function generateSqid(userContext, events, done) {
  // ASSIGNMENT_ID required - 458 for AWS dev, 1 for Fly dev
  const assignmentId = parseInt(process.env.ASSIGNMENT_ID);
  if (!assignmentId) {
    return done(new Error("ASSIGNMENT_ID environment variable is required"));
  }
  const sqid = sqids.encode([ANNOTATION_RESOURCE_ID, assignmentId]);
  userContext.vars.sqid = sqid;
  return done();
}

module.exports = {
  generateSqid,
};
