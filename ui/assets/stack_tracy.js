if (typeof(StackTracy) == "undefined") {

StackTracy = (function() {
  var sortation = {cumulatives: [], realtime_cumulatives: []};

  var toggle = function(event) {
    var group = $(event.target).closest("div").next("div.group");
    var comments = group.comments();
    if (comments.length) {
      group.html(comments.join("\n"));
    } else {
      group.toggle();
    }
  };

  $(function() {
    $(".toggler").live("click", toggle);
    $("[data-toggle]").click(function(event) {
      event.preventDefault();
      $(this).tab("show");
    });
  });

  return {
    version: "0.1.6",
    sort: function(section, column) {
      sortation[section][column] = sortation[section][column] == "asc" ? "desc" : "asc";
      $("#" + section + ">.body>div").tsort("span:eq(" + column + ")[abbr]", {
        sortFunction: function(a, b) {
          var order = (sortation[section][column] == "asc") ? 1 : -1;
          var av = column == 3 ? a.s : parseFloat(a.s);
          var bv = column == 3 ? b.s : parseFloat(b.s);
          if (av === bv) {
            return 0;
          } else {
            return (av > bv) ? order : -1 * order;
          }
        }
      });
    }
  };
})();

}