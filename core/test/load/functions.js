let counter = 0;

module.exports = {
  incrementCounter: function (context, events, done) {
    counter++;
    context.vars.uploadNumber = counter;
    return done();
  },
};
