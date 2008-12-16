// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function progressPercent(bar, percentage) {
  document.getElementById(bar).style.width =  parseInt(percentage*2)+"px";
  document.getElementById(bar).innerHTML= "<div align='center'>"+percentage+"%</div>"
}
