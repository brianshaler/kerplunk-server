React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
    DOM.section
      className: 'content'
    ,
      DOM.div null, '500, yo.'
      DOM.pre null,
        JSON.stringify (@props.error ? {}), null, 2
      DOM.pre null,
        JSON.stringify (@props.stack ? {}), null, 2
