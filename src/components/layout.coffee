_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
    ContentComponent = @props.getComponent @props.contentComponent

    DOM.div
      className: 'fixed'
    ,
      DOM.div
        className: 'wrapper relative'
      ,
        DOM.section
          className: 'content'
          style:
            height: '100%'
        ,
          ContentComponent _.extend {}, @props
