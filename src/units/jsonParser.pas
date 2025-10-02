unit JsonParser;
interface

function ParseJson(const jsonString: string): string;

implementation

uses
  SysUtils, Classes;

function ParseJson(const jsonString: string): string;
begin

  ParseJson := jsonString;
end;

end.