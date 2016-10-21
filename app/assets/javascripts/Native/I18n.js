var _user$project$Native_I18n = {
  't': function(resource) {
    // http://stackoverflow.com/questions/30521224/javascript-convert-pascalcase-to-underscore-case
    var snake = resource.ctor.replace(/\.?([A-Z]+)/g, function (x,y){return "_" + y.toLowerCase()}).replace(/^_/, "");
    return I18n.t(snake);
  }
};
