if (typeof(StackTracy) == "undefined") {

StackTracy = (function() {
  var sortation = [];

  var toggle = function(event) {
    $(event.target).closest("div").next("div.group").toggle();
  };

  $(function() {
    $(".toggler").live("click", toggle);
    $("[data-toggle]").click(function(event) {
      event.preventDefault();
      $(this).tab("show");
    });
  });

  return {
    version: "0.1.2",
    sort: function(column) {
      sortation[column] = sortation[column] == "asc" ? "desc" : "asc";
      $("#cumulatives>.body>div").tsort("span:eq(" + column + ")[abbr]", {
        sortFunction: function(a, b) {
          var order = (sortation[column] == "asc") ? 1 : -1;
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