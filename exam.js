var t=parseInt(document.currentScript.dataset.minutes,10)*60;
var c=document.getElementById("clk");
setInterval(function(){
  c.textContent="Time left: "+Math.floor(t/60)+":"+("0"+t%60).slice(-2);
  if(t--<=0)document.getElementById("f").submit();
},1000);
