module.exports = {
  mapO: (myObject) => (fnc) => {
    return Object.keys(myObject).reduce((prev, curr) => {
      return {
        ...prev,
        [curr]: fnc(myObject[curr]),
      };
    }, {});
  },
  squash: (arrObj) => {
    return arrObj.reduce((prev, current) => {
      return { ...prev, ...current };
    });
  },
};
