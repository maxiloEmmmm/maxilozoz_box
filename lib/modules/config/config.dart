class Config {
  Map dev = {};
  Map prod = {};
  bool prodModel = bool.fromEnvironment('dart.vm.product');

  void add(Map configs, {inDev = false}) {
    configs.forEach((k, v) {
      if(inDev) {
        this.dev[k] = v;
      }else {
        this.prod[k] = v;
      }
    });
  }

  dynamic get(String k) {
    return !this.prodModel 
      ? this.dev[k]
      : this.prod[k];
  }
}