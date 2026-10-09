(function () {
  var qs = [];
  var names = {mcq: "Single choice", multi: "Checkboxes", "long": "Written answer", file: "File upload"};
  function $(s) { return document.querySelector(s); }
  function all(s) { return document.querySelectorAll(s); }
  function sync() {
    var t = $("#qt").value;
    $("#opts").style.display = (t == "mcq" || t == "multi") ? "block" : "none";
  }
  function draw() {
    var l = $("#ql");
    l.textContent = "";
    qs.forEach(function (q, i) {
      var p = document.createElement("p");
      p.className = "sm";
      p.textContent = (i + 1) + ". [" + names[q.t] + "] " + q.q + " (" + q.m + " marks) ";
      var a = document.createElement("a");
      a.textContent = "Remove";
      a.href = "#";
      a.onclick = function (e) { e.preventDefault(); qs.splice(i, 1); draw(); };
      p.appendChild(a);
      l.appendChild(p);
    });
  }
  $("#qt").onchange = function () {
    all(".oc").forEach(function (c) { c.checked = false; });
    sync();
  };
  all(".oc").forEach(function (c) {
    c.onchange = function () {
      if ($("#qt").value == "mcq" && c.checked) {
        all(".oc").forEach(function (d) { if (d !== c) d.checked = false; });
      }
    };
  });
  $("#addq").onclick = function () {
    var t = $("#qt").value, q = $("#qq").value.trim(), m = parseInt($("#qm").value, 10) || 1;
    if (!q) { alert("Type the question first."); return; }
    var o = {t: t, q: q, m: String(m)};
    if (t == "mcq" || t == "multi") {
      var ts = all(".ot"), cs = all(".oc"), a = [];
      for (var i = 0; i < 4; i++) {
        var v = ts[i].value.trim();
        if (!v) { alert("Fill in all four options."); return; }
        o["o" + i] = v;
        if (cs[i].checked) a.push(i);
      }
      if (!a.length) { alert("Tick the correct answer."); return; }
      if (t == "mcq" && a.length > 1) { alert("Single choice can have only one correct answer."); return; }
      o.a = a.join(",");
      ts.forEach(function (x) { x.value = ""; });
      cs.forEach(function (x) { x.checked = false; });
    }
    qs.push(o);
    $("#qq").value = "";
    draw();
  };
  $("#xf").onsubmit = function () {
    if (!qs.length) { alert("Add at least one question."); return false; }
    $("#qjson").value = JSON.stringify(qs);
    return true;
  };
  sync();
})();
