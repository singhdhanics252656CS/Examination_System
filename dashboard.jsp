<%@ include file="_top.jspf" %>
<%!
String st(String l,int v){return "<div class='card st'><b>"+v+"</b>"+l+"</div>";}
%>
<h2>Welcome, <%=Db.h(me.get("name"))%></h2>
<div class="grid">
<%
String id=me.get("id");
List<Map<String,String>> rs=Db.t("results");
if("student".equals(role)){
 int n=0,c=0,s=0;
 for(Map<String,String> r:rs)if(id.equals(r.get("stu"))){n++;int[] x=Db.score(r);if(x[2]==0&&x[1]>0){c++;s+=x[0]*100/x[1];}}
 out.print(st("Exams available",Db.t("exams").size())+st("Attempted",n)+st("Average score %",c==0?0:s/c));
}else if("teacher".equals(role)){
 int ex=0,sub=0,gr=0;
 for(Map<String,String> e:Db.t("exams"))if(id.equals(e.get("by")))ex++;
 for(Map<String,String> r:rs){Map<String,String> e=Db.find("exams","id",r.get("exam"));if(e!=null&&id.equals(e.get("by"))){sub++;if(Db.score(r)[2]==1)gr++;}}
 out.print(st("My exams",ex)+st("Submissions",sub)+st("To grade",gr));
}else{
 int s=0,t=0;
 for(Map<String,String> u:Db.t("users")){if("student".equals(u.get("role")))s++;if("teacher".equals(u.get("role")))t++;}
 out.print(st("Students",s)+st("Teachers",t)+st("Exams",Db.t("exams").size())+st("Feedback",Db.t("feedback").size()));
}
%>
</div>
<%@ include file="_bot.jspf" %>
