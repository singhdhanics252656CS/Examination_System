<%@ include file="_top.jspf" %>
<%
if("POST".equals(request.getMethod())&&!"student".equals(role)){
 Map<String,String> r=Db.find("results","id",request.getParameter("rid"));
 Map<String,String> e=r==null?null:Db.find("exams","id",r.get("exam"));
 if(e!=null&&("admin".equals(role)||me.get("id").equals(e.get("by")))){
  int i=Db.num(request.getParameter("i"),-1);
  List<Map<String,String>> q=Db.qs(e);
  if(i>=0&&i<q.size()){
   Map<String,String> g=Db.grades(r);
   g.put(""+i,""+Math.max(0,Math.min(Db.num(q.get(i).get("m"),1),Db.num(request.getParameter("marks"),0))));
   r.put("g",Db.G.toJson(g));Db.save();
  }
 }
 response.sendRedirect("results.jsp");return;
}
if("student".equals(role)){ %>
<h2>My results</h2>
<% boolean any=false;
for(Map<String,String> r:Db.t("results")){
 if(!me.get("id").equals(r.get("stu")))continue;
 any=true;
 Map<String,String> e=Db.find("exams","id",r.get("exam"));
 int[] x=Db.score(r);%>
<div class="card"><b><%=e==null?"Deleted exam":Db.h(e.get("title"))%></b><p class="mut sm"><%=Db.h(r.get("at"))%></p>
<% if(x[2]==1){%><span class="tag">Written answers awaiting marks</span><%}%>
<p>Score<%=x[2]==1?" so far":""%>: <b><%=x[0]%>/<%=x[1]%></b> (<%=x[1]==0?0:x[0]*100/x[1]%>%)</p></div>
<% }
if(!any){%><p class="mut">You have not attempted any exam yet.</p><%}
}else{ %>
<h2>Submissions</h2>
<% for(Map<String,String> r:Db.t("results")){
 Map<String,String> e=Db.find("exams","id",r.get("exam"));
 if(e==null||!("admin".equals(role)||me.get("id").equals(e.get("by"))))continue;
 List<Map<String,String>> q=Db.qs(e);
 List<String> a=Db.answers(r);
 Map<String,String> g=Db.grades(r);
 Map<String,String> fm=Db.files(r);
 int[] x=Db.score(r);%>
<div class="card"><b><%=Db.h(e.get("title"))%></b>, <%=Db.h(Db.name(r.get("stu")))%>
<p class="sm mut"><%=Db.h(r.get("at"))%>. Score <%=x[0]%>/<%=x[1]%><%=x[2]==1?" (needs grading)":""%></p>
<% for(int i=0;i<q.size();i++){
 String t=q.get(i).get("t");
 if(!("long".equals(t)||"file".equals(t)))continue;
 String txt=i<a.size()?a.get(i):"";%>
<p class="sm"><b>Q:</b> <%=Db.h(q.get(i).get("q"))%><br>
<% if("long".equals(t)){%><b>Answer:</b> <%=txt.isEmpty()?"(no text)":Db.h(txt)%><br><%}%>
<%=Db.fileHtml(fm.get(""+i))%></p>
<form method="post"><input type="hidden" name="rid" value="<%=r.get("id")%>"><input type="hidden" name="i" value="<%=i%>">
<input type="number" name="marks" min="0" max="<%=q.get(i).get("m")%>" value="<%=g.containsKey(""+i)?g.get(""+i):""%>" placeholder="Marks out of <%=q.get(i).get("m")%>" required><button>Save marks</button></form>
<% } %></div>
<% }
} %>
<%@ include file="_bot.jspf" %>
