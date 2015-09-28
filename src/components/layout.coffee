_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    navActive: false

  componentWillReceiveProps: (newProps) ->
    if newProps.currentUrl != @props.currentUrl
      @setState
        navActive: false

  toggleNav: (e) ->
    e.preventDefault()
    @setState
      navActive: !@state.navActive

  render: ->
    url = @props.currentUrl #window.location.pathname
    wrapperClasses = [
      'wrapper'
      'relative'
    ]
    if @state.navActive
      wrapperClasses.push 'active'

    DOM.div
      className: 'fixed'
    ,
      DOM.div
        className: wrapperClasses.join ' '
      ,
        DOM.section
          className: 'content'
          style:
            height: '100%'
        ,
          @props.getComponent(@props.contentComponent) _.extend {key: @props.currentUrl}, @props
