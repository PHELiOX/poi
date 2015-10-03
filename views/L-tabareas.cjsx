path = require 'path-extra'
glob = require 'glob'
{__} = require 'i18n'
{_, $, React, ReactBootstrap, FontAwesome} = window
{TabbedArea, TabPane, DropdownButton, Grid, Col} = ReactBootstrap

$('poi-main').className += 'L-tabbed'
window.LTabbed = true

# Get components
components = glob.sync(path.join(ROOT, 'views', 'components', '*'))

PluginWrap = React.createClass
  shouldComponentUpdate: (nextProps, nextState)->
    false
  render: ->
    React.createElement @props.plugin.reactClass

# Discover plugins and remove unused plugins
plugins = glob.sync(path.join(ROOT, 'plugins', '*'))
exPlugins = glob.sync(path.join(EXROOT, 'plugins', '*'))
plugins = plugins.concat(exPlugins)
plugins = plugins.filter (filePath) ->
  # Every plugin will be required
  try
    plugin = require filePath
    return config.get "plugin.#{plugin.name}.enable", true
  catch e
    return false

components = components.map (filePath) ->
  component = require filePath
  component.priority = 10000 unless component.priority?
  component
components = components.filter (component) ->
  component.show isnt false and component.name != 'SettingsView' and component.priority > 0
components = _.sortBy(components, 'priority')

plugins = plugins.map (filePath) ->
  plugin = require filePath
  plugin.priority = 10000 unless plugin.priority?
  plugin
plugins = plugins.filter (plugin) ->
  plugin.show isnt false and plugin.priority <= 10000
plugins = _.sortBy(plugins, 'priority')
tabbedPlugins = plugins.filter (plugin) ->
  !plugin.handleClick?

settings = require path.join(ROOT, 'views', 'components', 'settings')
# compactmain = require path.join(ROOT, 'plugins', 'compactmain')
compactview = require path.join(ROOT, 'plugins', 'compactview')
fleet = require path.join(ROOT, 'views', 'components', 'ship')
main = require path.join(ROOT, 'views', 'components', 'main')
prophet = require path.join(ROOT, 'plugins', 'prophet')

lockedTab = false
ControlledTabArea = React.createClass
  getInitialState: ->
    key: [0, 2]
  handleSelect: (key) ->
    @setState {key} if key[0] isnt @state.key[0] or key[1] isnt @state.key[1]
  handleSelectLeft: (key) ->
    @handleSelect [key, @state.key[1]]
  handleSelectRight: (key) ->
    @handleSelect [@state.key[0], key]
  handleCtrlOrCmdTabKeyDown: ->
    @handleSelect [(@state.key[0] + 1) % components.length, @state.key[1]]
  handleCtrlOrCmdNumberKeyDown: (num) ->
    if num <= tabbedPlugins.length
      @handleSelect [@state.key[0], num - 1]
  handleShiftTabKeyDown: ->
    @handleSelect [@state.key[0], if @state.key[1]? then (@state.key[1] - 1 + tabbedPlugins.length) % tabbedPlugins.length else tabbedPlugins.length - 1]
  handleTabKeyDown: ->
    @handleSelect [@state.key[0], if @state.key[1]? then (@state.key[1] + 1) % tabbedPlugins.length else 1]
  handleKeyDown: ->
    return if @listener?
    @listener = true
    window.addEventListener 'keydown', (e) =>
      if e.keyCode is 9
        e.preventDefault()
        return if lockedTab and e.repeat
        lockedTab = true
        setTimeout ->
          lockedTab = false
        , 200
        if e.ctrlKey or e.metaKey
          @handleCtrlOrCmdTabKeyDown()
        else if e.shiftKey
          @handleShiftTabKeyDown()
        else
          @handleTabKeyDown()
      else if e.ctrlKey or e.metaKey
        if e.keyCode >= 49 and e.keyCode <= 57
          @handleCtrlOrCmdNumberKeyDown(e.keyCode - 48)
        else if e.keyCode is 48
          @handleCtrlOrCmdNumberKeyDown 10
  componentDidMount: ->
    window.addEventListener 'game.start', @handleKeyDown
    window.addEventListener 'tabarea.reload', @forceUpdate
  render: ->
    <div className='poi-tabs-container'>
      <div style={display: "flex"}>
        <div style={flex: 2}>
          <TabbedArea activeKey={@state.key[0]} onSelect={@handleSelectLeft} animation={false} style={flex: 1}>
          {
            [
              components.map (component, index) =>
                <TabPane key={index} eventKey={index} tab={component.displayName} id={component.name} className='poi-app-tabpane'>
                {
                  React.createElement component.reactClass,
                    selectedKey: @state.key[0]
                    index: index
                }
                </TabPane>
              <TabPane key={1000} eventKey={1000} tab={settings.displayName} id={settings.name} className='poi-app-tabpane'>
              {
                React.createElement settings.reactClass,
                  selectedKey: @state.key[0]
                  index: 1000
              }
              </TabPane>
            ]
          }
          </TabbedArea>
        </div>
        <div style={flex: 2}>
          <TabbedArea activeKey={@state.key[1]} onSelect={@handleSelectRight} animation={false} style={flex: 1}>
            <DropdownButton key={-1} eventKey={-1} tab={<span>{plugins[@state.key[1]]?.displayName || <span><FontAwesome name='sitemap' />{__ ' Plugins'}</span>}</span>} navItem={true}>
            {
              counter = -1
              plugins.map (plugin, index) =>
                if plugin.handleClick
                  <div key={index} eventKey={0} tab={plugin.displayName} id={plugin.name} onClick={plugin.handleClick} />
                else
                  eventKey = (counter += 1)
                  <TabPane key={index} eventKey={eventKey} tab={plugin.displayName} id={plugin.name} className='poi-app-tabpane'>
                    <PluginWrap plugin={plugin} selectedKey={@state.key[1]} index={eventKey} />
                  </TabPane>
            }
            </DropdownButton>
          </TabbedArea>
        </div>
      </div>
    </div>

AdditionalTabArea = React.createClass
  render: ->
    <div key={0} className="poi-app-2ndpane" id={compactview.name} style={width:"100%", overflowX:"hidden", overflowY:"scroll"}>
      {
        React.createElement compactview.reactClass
      }
    </div>

PlusTabArea = React.createClass
  render: ->
    <div key={1} className="poi-app-2ndpane" id={prophet.name} style={width:"100%", overflowX:"hidden", overflowY:"scroll"}>
      {
        React.createElement prophet.reactClass
      }
    </div>

module.exports =
  ControlledTabArea: ControlledTabArea
  AdditionalTabArea: AdditionalTabArea
  PlusTabArea: PlusTabArea
