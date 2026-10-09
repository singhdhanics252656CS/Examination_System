<%@ include file="_top.jspf" %>
<%
if("POST".equals(request.getMethod())){
 String act=request.getParameter("act");
 if("create".equals(act)&&"teacher".equals(role)){
  List<Map<String,String>> q=Db.cleanQs(request.getParameter("qjson"));
  String title=String.valueOf(request.getParameter("title")).trim();
  if(!q.isEmpty()&&!title.isEmpty()){
   Db.t("exams").add(Db.row("id",Db.id(),"title",title,"subject",String.valueOf(request.getParameter("subject")).trim(),"dur",""+Math.max(1,Db.num(request.getParameter("dur"),15)),"by",me.get("id"),"q",Db.G.toJson(q)));
   Db.save();
  }
 }else if("del".equals(act)){
  Map<String,String> e=Db.find("exams","id",request.getParameter("id"));
  if(e!=null&&("admin".equals(role)||me.get("id").equals(e.get("by")))){
   String eid=e.get("id");
   Db.t("exams").remove(e);
   Db.t("results").removeIf(r->eid.equals(r.get("exam")));
   Db.dropFilesWhere("exam",eid);
   Db.save();
  }
 }
 response.sendRedirect("exams.jsp");return;
}
%>
<h2>Exams</h2>
<% if("teacher".equals(role)){ %>
<div class="card"><h3>Create exam</h3>
<form method="post" id="xf"><input type="hidden" name="act" value="create"><input type="hidden" name="qjson" id="qjson">
<input name="title" placeholder="Exam title" required><input name="subject" placeholder="Subject" required><input name="dur" type="number" min="1" value="15" placeholder="Minutes">
<h3>Add a question</h3>
<select id="qt"><option value="mcq">Single choice (pick one)</option><option value="multi">Checkboxes (pick several)</option><option value="long">Written answer (file or photo optional)</option><option value="file">File or photo upload only</option></select>
<textarea id="qq" rows="2" placeholder="Question"></textarea>
<div id="opts"><p class="mut sm">Type the options and tick the correct answer(s)</p>
<% for(String L:new String[]{"A","B","C","D"}){%><div class="orow"><input type="checkbox" class="oc" aria-label="Correct answer"><input class="ot" placeholder="Option <%=L%>"></div><%}%>
</div>
<input id="qm" type="number" min="1" value="1" placeholder="Marks">
<button type="button" class="s" id="addq">Add question</button>
<div id="ql"></div>
<button>Publish exam</button></form></div>
<script src="builder.js"></script>
<% }
for(Map<String,String> e:Db.t("exams")){
 if("teacher".equals(role)&&!me.get("id").equals(e.get("by")))continue;
 boolean done=false;
 for(Map<String,String> r:Db.t("results"))if(r.get("exam").equals(e.get("id"))&&r.get("stu").equals(me.get("id")))done=true;
%>
<div class="card"><b><%=Db.h(e.get("title"))%></b>
<p class="mut sm"><%=Db.h(e.get("subject"))%>, <%=Db.h(e.get("dur"))%> min, <%=Db.qs(e).size()%> questions. By <%=Db.h(Db.name(e.get("by")))%></p>
<% if("student".equals(role)){ if(done){ %><span class="tag">Completed</span><% }else{ %><a class="btn" href="take.jsp?id=<%=e.get("id")%>">Start exam</a><% } }else{ %>
<form method="post"><input type="hidden" name="act" value="del"><input type="hidden" name="id" value="<%=e.get("id")%>"><button class="d">Delete</button></form>
<% } %></div>
<% } %>
<%@ include file="_bot.jspf" %>
