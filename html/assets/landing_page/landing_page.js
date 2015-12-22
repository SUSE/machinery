$(document).ready(function () {
    // Set up filter
    $(".filterable").searcher({
        inputSelector: "#filter"
    });
    $("#reset-filter").click(function () {
        $("#filter").val("").change()
    });

})
