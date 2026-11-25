import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import "../../components" as Components

ShellRoot {
  id: root
  property var uiCase: ({width:400,fontSize:12})
  property var fixture: ({team:[],global:[]})
  property int activations: 0
  property string selected: ""
  function readText(path) {
    var request = new XMLHttpRequest(); request.open("GET",Qt.resolvedUrl(path),false);request.send();return request.responseText
  }
  function state(entries, teamId) {
    return {teamId:teamId, dateKey:"2026-11-24",entries:entries,hasData:true,loading:false,stale:false,partial:false,
      coverageStart:"2026-11-24",coverageEnd:"2026-12-28",lastSuccessAt:"2026-11-24T16:00:00Z"}
  }
  QtObject { id: logos; function sourceFor(url) { return "" } }
  Window {
    id: window
    visible:true
    width:root.uiCase.width
    height:640
    color:Commons.Color.popups.background
    Rectangle { anchors.fill:parent; color:Commons.Color.popups.background }
    Item { id:headerFocus }
    Text {
      x:16;y:12;text:calendar.globalMode?"Calendar":"Team schedule";textFormat:Text.PlainText
      color:Commons.Color.popups.text;font.family:"Adwaita Sans";font.pixelSize:Commons.Style.font.subtitle;font.bold:true
    }
    Components.UpcomingCalendar {
      id:calendar
      x:16;y:48;width:window.width-32;height:window.height-y-16
      teamOptions:[{value:"",label:"All followed leagues"},{value:"nhl:6",label:"Boston Bruins · NHL"}]
      teamId:"nhl:6"
      todayDateKey:"2026-11-24"
      selectedDateKey:"2026-11-24"
      monthKey:"2026-11-01"
      currentTime:Date.parse("2026-11-24T16:05:00Z")
      imageStore:logos
      onDateSelected:function(dateKey){root.activations++;root.selected=dateKey}
    }
    Test.TestCase {
      id:checks
      when:false
      function check(value,message){if(!value)throw new Error(message)}
      function items(object,predicate,found){
        if(!object)return found
        if(predicate(object))found.push(object)
        var children=object.children||[]
        for(var i=0;i<children.length;i++)items(children[i],predicate,found)
        return found
      }
      function rows(){return items(calendar,function(item){return item.visible&&"gameId"in item&&"dateKey"in item&&item.activeFocusOnTab},[])}
      function capture(name){
        var done=false,saved=false
        window.contentItem.grabToImage(function(result){saved=result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE")+"/"+name+".png");done=true})
        tryVerify(function(){return done},5000);check(saved,"Capture failed")
      }
      function checkColumns(){
        for(var row of rows()){
          var date=findChild(row,"agendaDate"),matchup=findChild(row,"agendaMatchup"),time=findChild(row,"agendaTime")
          check(date&&matchup&&time,"Missing aligned column")
          check(date.x+date.width<=matchup.x+1,"Date overlaps matchup")
          if(row.stackedTime){
            check(time.y>=matchup.y+matchup.height-1,"Stacked time overlaps matchup")
            check(Math.abs(time.x-matchup.x)<1,"Stacked time is not aligned with matchup")
            check(time.y+time.height<=time.parent.height+1,"Stacked time crosses row edge")
          }else check(matchup.x+matchup.width<=time.x+1,"Matchup overlaps time")
          check(time.x+time.width<=row.width+1,"Time crosses row edge")
          check(matchup.width>0&&row.height>0,"Row lost readable space")
          check(matchup.y>=-1&&matchup.y+matchup.height<=matchup.parent.height+1,"Matchup crosses row height")
        }
      }
      function run(){
        try{
          root.uiCase=JSON.parse(root.readText("ui-case.json"));root.fixture=JSON.parse(root.readText("agenda-fixture.json"))
          Commons.Color.loadUserShell("");Commons.Color.loadColors(root.readText("theme/colors.toml"));Commons.Color.loadShell(root.readText("theme/shell.toml"))
          Commons.Style.fontFamily="JetBrainsMono Nerd Font";Commons.Style.fontBaseSize=root.uiCase.fontSize;Commons.Style.cornerRadius=8
          calendar.scheduleState=root.state(root.fixture.team,"nhl:6");wait(120)
          check(calendar.chooserOpen===false,"Closed chooser claimed ownership")
          var nextMatchup=findChild(calendar,"calendarNextMatchup")
          check(nextMatchup&&nextMatchup.game.id===root.fixture.team[0].game.id,"Next up does not use the exact normalized game")
          check(nextMatchup.dateText.indexOf("Nov 25")!==-1&&!nextMatchup.showStatus,"Scheduled hero lost the exact date or exposed a retained clock")
          var unknownTime=JSON.parse(JSON.stringify(root.fixture.team));unknownTime[0].timeKnown=false
          calendar.scheduleState=root.state(unknownTime,"nhl:6");wait(25)
          check(nextMatchup.startLabel==="Time TBD"&&!nextMatchup.timeKnown,"Unknown next time became a fabricated start time")
          calendar.scheduleState=root.state(root.fixture.team,"nhl:6");wait(25)
          var jump=items(calendar,function(item){return item.visible&&"tooltipText"in item&&item.tooltipText==="Jump to the next listed game"},[])[0]
          check(jump,"Next up lost View day")
          jump.forceActiveFocus();keyClick(Qt.Key_Return);check(root.selected===root.fixture.team[0].dateKey,"Next up View day opened a different fixture date")
          check(calendar.agendaEntries.length===root.fixture.team.length-1,"Featured game duplicated in later agenda")
          var gameRows=rows();check(gameRows.length===calendar.agendaEntries.length,"Week headings displaced game indexes")
          check(gameRows[0].sectionLabel==="This week","First week label missing")
          check(gameRows.some(function(row){return row.sectionLabel==="Next week"}),"Next week divider missing")
          check(gameRows.some(function(row){return row.sectionLabel==="Week of Dec 7"}),"Later week divider missing")
          checkColumns();capture("agenda-team")
          var initialTimeWidth=gameRows[0].timeWidth
          Commons.Style.fontBaseSize=root.uiCase.fontSize+4;wait(40)
          check(rows()[0].timeWidth>initialTimeWidth,"Time column did not react to in-place font change")
          checkColumns();capture("agenda-font-change")
          Commons.Style.fontBaseSize=root.uiCase.fontSize;wait(40)
          check(rows()[0].timeWidth===initialTimeWidth,"Time column did not restore its original font metrics")
          var last=gameRows[gameRows.length-1];last.forceActiveFocus();wait(50)
          var snapshot=calendar.captureContext()
          check(snapshot.focusKind==="agenda"&&snapshot.gameId===last.gameId,"Context lost canonical last game")
          check(snapshot.scrollY>0,"Fixture must overflow vertically")
          headerFocus.forceActiveFocus();wait(20)
          check(calendar.captureContext().gameId===snapshot.gameId,"Header focus erased the remembered agenda action")
          last.forceActiveFocus();wait(20)
          var before=root.activations;keyClick(Qt.Key_Return);check(root.activations===before+1&&root.selected===last.dateKey,"Keyboard agenda action did not fire exactly once")
          calendar.visible=false;wait(20);calendar.visible=true;calendar.restoreContext(snapshot);wait(80)
          check(calendar.captureContext().gameId===snapshot.gameId,"Restoration focused a week header instead of game")
          check(Math.abs(calendar.captureContext().scrollY-snapshot.scrollY)<1,"Restoration lost agenda scroll")
          last=rows()[rows().length-1];mouseClick(last,last.width/2,last.height*.75,Qt.LeftButton,Qt.NoModifier,20);wait(20)
          check(root.activations===before+2,"Pointer agenda action fired more than once")
          calendar.focusCalendar();wait(30)
          var reached={}
          for(var n=0;n<40;n++){
            keyClick(Qt.Key_Tab);wait(8)
            for(var row of rows())if(row.activeFocus)reached[row.gameId]=true
            if(Object.keys(reached).length===gameRows.length)break
          }
          check(Object.keys(reached).length===gameRows.length,"Native Tab could not reach every canonical game")
          calendar.teamId="";calendar.scheduleState=root.state(root.fixture.global,"");calendar.focusCalendar();wait(60)
          var monthTitle=findChild(calendar,"calendarMonthTitle")
          check(monthTitle&&!monthTitle.truncated,"Responsive month title clipped its month/year")
          checkColumns();check(rows().length===root.fixture.global.length,"Global agenda lost games")
          check(rows().some(function(row){return row.timeText==="Time TBD"}),"TBD became a fabricated time")
          check(rows().some(function(row){return row.timeText==="Live"&&row.scoreText!==""}),"Fresh live score/status missing")
          capture("agenda-global")
          calendar.scheduleState=Object.assign({},calendar.scheduleState,{stale:true});wait(30)
          check(rows().every(function(row){return row.timeText!=="Live"&&row.timeText!=="Intermission"}),"Retained schedule claimed current live state")
          check(calendar.notice.stale&&calendar.notice.visible,"Retained rows lost parent freshness notice")
          console.log("AGENDA_PRESENTATION_PASS "+root.uiCase.name);Qt.quit()
        }catch(error){console.error("AGENDA_PRESENTATION_FAIL "+String(error)+" "+error.stack);Qt.quit()}
      }
    }
    Timer{interval:200;running:true;onTriggered:checks.run()}
  }
}
