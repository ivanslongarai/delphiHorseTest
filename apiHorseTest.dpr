program apiHorseTest;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Horse,
  System.SysUtils,
  Horse.Jhonson,
  System.JSON,
  Horse.BasicAuthentication,
  Horse.JWT,
  JOSE.Core.JWT,
  JOSE.Core.Builder;

var
  FCustomers: TJSONArray;

begin

  THorse.Use(Jhonson);

  THorse.Use(HorseBasicAuthentication(
    function(const AUsername, APassword: string): Boolean
    begin
      Result := AUsername.Equals('ivan') and APassword.Equals('123');
      //Authorization: Basic aXZhbjoxMjM=
    end));

  //THorse.Use(HorseJWT('my_very_long_and_safe_cecret_key'));
  //generated token:
  //eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJU0wgQ29tcGFueSIsInN1YiI6IklTTCBTdWJqZWN0IiwiZXhwIjoxNjI4NDU4ODY5LCJub21lIjoiSXZhbiBMb25nYXJhaSIsIm12cCI6dHJ1ZX0.oGTZMr9fh5Tv41EusO14qmBGvT1YxWbLl2jvhThBWmM

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Writeln('Request GET/ping');
      Res.Send('pong');
    end);

  THorse.Post('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LBody: TJSONObject;
    begin
      Writeln('Request POST/ping');
      LBody := Req.Body<TJSONObject>;
      Res.Send<TJSONObject>(LBody);
    end);

  THorse.Get('/customers',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Writeln('Request GET/customers');
      FCustomers := TJSONArray.Create;
      try
        FCustomers.Add(TJSONObject.Create(TJSONPair.Create('name', 'Ivan Longarai')));
        FCustomers.Add(TJSONObject.Create(TJSONPair.Create('name', 'Maria José')));
        FCustomers.Add(TJSONObject.Create(TJSONPair.Create('name', 'José Maria')));
        Res.Send<TJSONArray>(FCustomers);
        // raise Exception.Create('Error getting customers'); {just for testing}
      except
        on E: Exception do
        begin
          Res.Send(TJSONObject.Create(TJSONPair.Create('Error message',
            E.Message))).Status(500);
        end;
      end;
    end);

  THorse.Get('/login',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
     oToken: TJWT;
     sCompactToken : string;
    begin
      oToken := TJWT.Create;
      try
        oToken.Claims.Issuer := 'ISL Company';
        oToken.Claims.Subject := 'ISL Subject';
        oToken.Claims.Expiration := Now + 1;
        oToken.Claims.SetClaimOfType<string>('name', 'Ivan Longarai');
        oToken.Claims.SetClaimOfType<Boolean>('brasilian', True);
        sCompactToken := TJOSE.SHA256CompactToken('my_very_long_and_safe_cecret_key', oToken);
        Res.Send(sCompactToken);
      finally
        FreeAndNil(oToken);
      end;
    end);

  THorse.Listen(9000,
    procedure(Horse: THorse)
    begin
      Writeln('Server listening at port: ' + Horse.Port.ToString);
    end);

end.
