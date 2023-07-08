class SheetsColumn{
  static final String Res = "Res";
  static final String Time = "Time";
  static final String Temparature = "Temparature";
  static final String Cpu_Load  = "Cpu_Load";
  static final String Stack_Load  = "Stack_Load";
  static final String Cloud_id  = "Cloud_id";

  static List<String> getColumns() => [Res,Time, Temparature, Cpu_Load,Stack_Load,Cloud_id];
}