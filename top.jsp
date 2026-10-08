<%@ include file="_top.jspf" %>
<h2>Top students</h2><div class="card">
<%
Map<String,int[]> m=new HashMap<>();
for(Map<String,String> r:Db.t("results")){
 int[] x=Db.score(r);
 if(x[2]==1||x[1]==0)continue;
 int[] a=m.computeIfAbsent(r.get("stu"),z->new int[2]);
 a[0]+=x[0]*100/x[1];a[1]++;
}
List<Map.Entry<String,int[]>> l=new ArrayList<>(m.entrySet());
l.sort((p,w)->w.getValue()[0]/w.getValue()[1]-p.getValue()[0]/p.getValue()[1]);
int k=0;
for(Map.Entry<String,int[]> en:l){
 if(k++==10)break;%>
<div class="row"><span><%=k%>. <%=Db.h(Db.name(en.getKey()))%></span><b><%=en.getValue()[0]/en.getValue()[1]%>%</b><span class="mut sm"><%=en.getValue()[1]%> exam(s)</span></div>
<% }
if(l.isEmpty()){%><p class="mut">Rankings appear after exams are graded.</p><%}%>
</div>
<%@ include file="_bot.jspf" %>
