React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
    DOM.section
      className: 'content'
    ,
      DOM.div null, '500, yo.'
      DOM.pre null,
        if typeof @props.error is 'object'
          JSON.stringify (@props.error ? {}), null, 2
        else
          @props.error
      if @props.stack
        DOM.pre null, @props.stack
      else
        null
