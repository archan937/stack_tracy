if (typeof(StackTracy) == "undefined") {

StackTracy = (function() {
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
    version: "0.1.0"
  };
})();

}