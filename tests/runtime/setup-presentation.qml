import QtQuick
import QtQuick.Window
import QtTest as Test
import Quickshell
import qs.Commons as Commons
import qs.Ui as Ui
import "../../components" as Components
import "../../model/SettingsModel.js" as SettingsModel
import "../../providers/LeagueCatalog.js" as LeagueCatalog
import "../../providers/NhlTeamCatalog.js" as NhlTeamCatalog
import "../../providers/EspnTeamCatalog.js" as EspnTeamCatalog

ShellRoot {
  id:root
  property var uiCase:({width:400,fontSize:12})
  property int revision:0
  property int escapes:0
  property bool started:false
  readonly property var leagues:LeagueCatalog.listLeagues()
  readonly property var teams:NhlTeamCatalog.listTeams().concat(EspnTeamCatalog.listTeamsForLeagues(["nfl","nba"]))
  function initial(){return Object.assign({},SettingsModel.createDefaults(),{favoriteTeamIds:[],enabledLeagues:["nhl"],followedLeagueIds:["nhl"],ticker:{enabled:false,position:"top",speed:"fast"}})}
  function readText(path){var request=new XMLHttpRequest();request.open("GET",Qt.resolvedUrl(path),false);request.send();return request.responseText}
  QtObject {
    id:store
    property bool ready:true
    property var settings:root.initial()
    property var watchedGames:[]
    property int mutations:0
    property string lastFavoriteLabel:""
    onSettingsChanged:if(root.started)root.revision++
    function isLeagueEnabled(id){return settings.enabledLeagues.indexOf(id)!==-1}
    function toggleFavoriteTeam(id,label){mutations++;lastFavoriteLabel=label||"";settings=SettingsModel.toggleFavoriteTeam(settings,id);return true}
    function toggleLeague(id){mutations++;settings=SettingsModel.toggleLeague(settings,id)}
    function toggleFollowedLeague(id){mutations++;settings=SettingsModel.toggleFollowedLeague(settings,id)}
    function moveFollowedLeague(id,direction){mutations++;settings=SettingsModel.moveFollowedLeague(settings,id,direction)}
    function toggleNotification(key){mutations++;settings=SettingsModel.toggleNotification(settings,key)}
    function setTicker(key,value){mutations++;settings=SettingsModel.setTicker(settings,key,value)}
  }
  QtObject {id:notifications;function sendTestNotification(){}}
  QtObject {id:logos;function sourceFor(url){return ""}}
  Window {
    id:window
    width:root.uiCase.width;height:640;visible:true;color:Commons.Color.popups.background
    Rectangle{anchors.fill:parent;color:Commons.Color.popups.background}
    Text{x:16;y:12;text:"Settings";textFormat:Text.PlainText;color:Commons.Color.popups.text;font.family:"Adwaita Sans";font.pixelSize:Commons.Style.font.subtitle;font.bold:true}
    Ui.PanelKeyCatcher {
      id:catcher
      anchors.fill:parent
      blocked:hub.inputActive
      onTextKey:function(text){hub.handleTextKey(text)}
      onMoveRequested:function(dx,dy){hub.moveCursor(dx,dy)}
      onActivateRequested:hub.activateCursor()
      onCloseRequested:root.escapes++
      Components.SettingsHub {
        id:hub
        x:16;y:48;width:window.width-32
        settingsStore:store
        teams:root.teams;leagues:root.leagues;notificationService:notifications;imageStore:logos
        settingsRevision:root.revision
        onContentFocusRequested:catcher.forceActiveFocus()
        onEscapeRequested:root.escapes++
      }
    }
    Test.TestCase {
      id:checks
      when:false
      function check(value,message){if(!value)throw new Error(message)}
      function all(object,predicate,result){if(!object)return result;if(predicate(object))result.push(object);for(var child of object.children||[])all(child,predicate,result);return result}
      function first(object,predicate){var found=all(object,predicate,[]);return found.length?found[0]:null}
      function typeText(value){for(var i=0;i<value.length;i++)keyClick(value.charAt(i).toUpperCase().charCodeAt(0))}
      function capture(name){var done=false,saved=false;window.contentItem.grabToImage(function(result){saved=result.saveToFile(Quickshell.env("SPORTRAY_TEST_CAPTURE")+"/"+name+".png");done=true});tryVerify(function(){return done},5000);check(saved,"Capture failed")}
      function picker(){return first(hub,function(item){return "setupGuideVisible"in item&&"visibleTeams"in item})}
      function protectedSettings(){var value=Object.assign({},store.settings);delete value.favoriteTeamIds;return JSON.stringify(value)}
      function assertBounds(p){var list=findChild(p,"setupTeamList");check(list&&list.height>=Commons.Style.space(96),"Guide starved team list");check(list.height<=Commons.Style.space(360),"Team list escaped its bounded area");var bottom=list.mapToItem(window.contentItem,0,list.height).y;check(bottom<=window.height-12,"Inactive outer scroll would clip team list: "+bottom);return list}
      function run(){
        try{
          root.uiCase=JSON.parse(root.readText("ui-case.json"));Commons.Color.loadUserShell("");Commons.Color.loadColors(root.readText("theme/colors.toml"));Commons.Color.loadShell(root.readText("theme/shell.toml"));Commons.Style.fontFamily="JetBrainsMono Nerd Font";Commons.Style.fontBaseSize=root.uiCase.fontSize;Commons.Style.cornerRadius=8
          root.started=true;hub.reset("teams");wait(100)
          var p=picker();check(p&&p.setupGuideVisible,"Zero favorites did not show first-use guidance")
          var list=assertBounds(p),pickerHeight=p.height,listHeight=list.height,listTop=list.mapToItem(p,0,0).y
          var protectedBefore=protectedSettings();check(store.mutations===0,"Opening setup changed preferences")
          capture("setup-first-use")
          var firstNhl=-1
          for(var i=0;i<p.visibleTeams.length;i++)if(p.visibleTeams[i].league==="nhl"){firstNhl=i;break}
          check(firstNhl>=0,"No enabled NHL fixture")
          var chosen=p.visibleTeams[firstNhl];p.cursorIndex=firstNhl;p.ensureCursorVisible();wait(35)
          var delegate=list.itemAtIndex(firstNhl);check(delegate,"Favorite target not laid out")
          mouseClick(delegate,delegate.width/2,delegate.height/2,Qt.LeftButton,Qt.NoModifier,20);wait(50)
          check(p.selectedCount===1&&p.setupGuideVisible,"First favorite collapsed the session guidance")
          check(Math.abs(p.height-pickerHeight)<1&&Math.abs(list.height-listHeight)<1&&Math.abs(list.mapToItem(p,0,0).y-listTop)<1,"First favorite moved the setup geometry")
          check(p.visibleTeams[p.cursorIndex].id===chosen.id,"Favorite sorting silently moved the cursor to another team")
          check(store.lastFavoriteLabel===chosen.name,"Favorite confirmation lost team label")
          check(protectedSettings()===protectedBefore,"Choosing a team changed ticker/league preferences")
          p.focusSearch();typeText("v");wait(20)
          check(hub.destination==="teams"&&p.query.toLowerCase()==="v","Search V was stolen by league shortcut")
          check(store.mutations===1,"Typing mutated a preference")
          keyClick(Qt.Key_Escape);wait(20);check(root.escapes===1,"Search Escape did not retain its route")
          p.clearSearch();p.focusSearch();keyClick(Qt.Key_Down);wait(30)
          check(hub.contentFocused&&!hub.inputActive&&catcher.activeFocus,"Browse did not own keyboard input")
          var mutationCount=store.mutations;keyClick(Qt.Key_V);wait(40)
          check(hub.destination==="sports"&&hub.contentFocused&&catcher.activeFocus,"Browse V did not review leagues")
          check(store.mutations===mutationCount,"Reviewing leagues toggled a preference")
          capture("setup-leagues")
          hub.selectDestination("teams");wait(40)
          check(p.setupGuideVisible,"Changing sections reset the open-session guide")
          var nfl=root.teams.filter(function(team){return team.league==="nfl"})[0];check(nfl,"No disabled NFL fixture")
          p.clearSearch();p.focusSearch();typeText(nfl.abbreviation);wait(20);keyClick(Qt.Key_Down);wait(20);keyClick(Qt.Key_Return);wait(50)
          check(store.settings.favoriteTeamIds.indexOf(nfl.id)!==-1&&p.disabledSelectedCount===1,"Disabled favorite did not explain its missing scores")
          check(store.settings.enabledLeagues.join(",")==="nhl"&&store.settings.followedLeagueIds.join(",")==="nhl","Choosing disabled team automatically enabled/followed its league")
          check(protectedSettings()===protectedBefore,"Disabled favorite changed ticker/league preferences")
          var caption=first(p,function(item){return "text"in item&&String(item.text).indexOf("league disabled")!==-1});check(caption,"Disabled league row caption missing")
          capture("setup-disabled-league")
          var review=findChild(p,"reviewLeaguesButton");check(review,"Review leagues button unavailable")
          p.focusSearch();keyClick(Qt.Key_Backtab,Qt.ShiftModifier);wait(20)
          check(review.activeFocus&&hub.inputActive,"Native Shift+Tab could not reach Review leagues")
          keyClick(Qt.Key_Escape);wait(20);check(root.escapes===2,"Focused Review leagues did not own Escape")
          mutationCount=store.mutations;keyClick(Qt.Key_Return);wait(30)
          check(hub.destination==="sports"&&store.mutations===mutationCount,"Review button keyboard action toggled a team")
          hub.selectDestination("teams");wait(30)
          review=findChild(p,"reviewLeaguesButton")
          mutationCount=store.mutations;mouseClick(review,review.width/2,review.height/2,Qt.LeftButton,Qt.NoModifier,20);wait(40)
          check(hub.destination==="sports"&&!hub.inputActive&&catcher.activeFocus,"Review button did not hand focus to league controls")
          check(store.mutations===mutationCount,"Review button mutated preferences")
          hub.reset("teams");catcher.forceActiveFocus();wait(40)
          check(!p.setupGuideVisible,"New session still showed first-use guidance after selection")
          p.clearSearch();hub.contentFocused=true;p.moveCursor(10000);wait(45);list=assertBounds(p)
          var last=list.itemAtIndex(p.cursorIndex);check(last,"Last team is unreachable")
          var point=last.mapToItem(window.contentItem,0,0);check(point.y>=0&&point.y+last.height<=window.height-12,"Last team cannot be seen with inactive outer scroll")
          check(p.cursorBounds().bottom<=p.height+1,"Cursor bounds escaped picker")
          capture("setup-returning")
          store.ready=false;store.settings=root.initial();hub.reset("teams");wait(15)
          check(p.setupGuidePending&&!p.setupGuideVisible,"Unloaded preferences were mistaken for first use")
          store.settings=SettingsModel.toggleFavoriteTeam(store.settings,chosen.id);store.ready=true;wait(25)
          check(!p.setupGuideVisible&&!p.setupGuidePending,"Loaded existing favorites were mistaken for first use")
          console.log("SETUP_PRESENTATION_PASS "+root.uiCase.name);Qt.quit()
        }catch(error){console.error("SETUP_PRESENTATION_FAIL "+String(error)+" "+error.stack);Qt.quit()}
      }
    }
    Timer{interval:200;running:true;onTriggered:checks.run()}
  }
}
