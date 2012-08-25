jQuery.fn.comments = function() {
  var comments = [];

  this.each(function(i, node) {
    var child = node.firstChild;
    while (child) {
      if (child.nodeType === 8) {
        comments.push(child.nodeValue);
      }
      child = child.nextSibling;
    }
  });

  return comments;
};