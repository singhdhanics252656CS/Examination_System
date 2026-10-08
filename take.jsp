<%@ include file="_top.jspf" %>
<%
Map<String,String> e=Db.find("exams","id",request.getParameter("id"));
if(e==null||!"student".equals(role)){response.sendRedirect("exams.jsp");return;}
for(Map<String,String> r:Db.t("results"))if(r.get("exam").equals(e.get("id"))&&r.get("stu").equals(me.get("id"))){response.sendRedirect("results.jsp");return;}
List<Map<String,String>> q=Db.qs(e);
if("POST".equals(request.getMethod())){
 List<String> a=new ArrayList<>();
 for(int i=0;i<q.size();i++){String v=request.getParameter("q"+i);a.add(v==null?"":v.trim());}
 Db.t("results").add(Db.row("id",Db.id(),"exam",e.get("id"),"stu",me.get("id"),"a",Db.G.toJson(a),"g","{}","at",new Date().toString()));
 Db.save();response.sendRedirect("results.jsp");return;
}
%>
<h2><%=Db.h(e.get("title"))%></h2><div class="clk" id="clk"></div>
<form method="post" id="f">
<% for(int i=0;i<q.size();i++){Map<String,String> x=q.get(i);%>
<div class="card"><p><b>Q<%=i+1%>.</b> <%=Db.h(x.get("q"))%> <span class="mut">(<%=x.get("m")%> marks)</span></p>
<% if("mcq".equals(x.get("t"))){for(int j=0;j<4;j++){%><label class="op"><input type="radio" name="q<%=i%>" value="<%=j%>"> <%=Db.h(x.get("o"+j))%></label><%}}else{%><textarea name="q<%=i%>" rows="6" placeholder="Write your answer"></textarea><%}%>
</div>
<% } %>
<button>Submit exam</button></form>
<script src="exam.js" data-minutes="<%=Db.num(e.get("dur"),15)%>"></script>
<%@ include file="_bot.jspf" %>
