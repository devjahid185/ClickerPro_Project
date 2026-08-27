<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $subjectLine ?? 'Graphy7 security code' }}</title>
</head>
<body style="margin:0;padding:0;background:#f4f0ea;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;color:#191715;">
    <div style="display:none;max-height:0;overflow:hidden;color:transparent;opacity:0;">
        {{ $preheader ?? 'Use this secure code to continue in Graphy7.' }}
    </div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f0ea;margin:0;padding:32px 12px;">
        <tr>
            <td align="center">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#ffffff;border-radius:22px;overflow:hidden;border:1px solid #e7dfd3;box-shadow:0 18px 50px rgba(25,23,21,0.10);">
                    <tr>
                        <td style="background:#17120d;padding:28px 32px;color:#fff;">
                            <div style="font-size:13px;letter-spacing:2.8px;text-transform:uppercase;color:#f3a23a;font-weight:800;">Graphy7</div>
                            <div style="font-size:24px;line-height:1.25;font-weight:800;margin-top:8px;">{{ $headline }}</div>
                            <div style="font-size:14px;line-height:1.6;color:#d8d1c8;margin-top:8px;">{{ $subhead ?? 'Photography studio management, secured.' }}</div>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:34px 32px 28px;">
                            <p style="font-size:16px;line-height:1.7;margin:0 0 20px;color:#3a342d;">{{ $intro }}</p>

                            <div style="background:#fff7eb;border:1px solid #f2cf9a;border-radius:18px;padding:22px 18px;text-align:center;margin:22px 0;">
                                <div style="font-size:12px;letter-spacing:2px;text-transform:uppercase;color:#9a5b10;font-weight:800;margin-bottom:10px;">{{ $contextLabel ?? 'Your secure code' }}</div>
                                <div style="font-family:'SFMono-Regular',Consolas,'Liberation Mono',monospace;font-size:38px;line-height:1;letter-spacing:8px;font-weight:900;color:#191715;">{{ $code }}</div>
                            </div>

                            <p style="font-size:14px;line-height:1.7;margin:0;color:#5e554c;">
                                This code expires in <strong style="color:#191715;">{{ $expiresIn }}</strong>. For your security, do not share it with anyone.
                            </p>

                            <div style="border-top:1px solid #eee5da;margin:26px 0 0;padding-top:20px;">
                                <p style="font-size:13px;line-height:1.7;color:#7a7065;margin:0;">
                                    {{ $securityNote ?? 'If you did not request this code, you can safely ignore this email. Your account remains protected.' }}
                                </p>
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="background:#fbf8f3;padding:20px 32px;border-top:1px solid #eee5da;">
                            <p style="font-size:12px;line-height:1.6;color:#8a8075;margin:0;">
                                Sent by Graphy7. This is an automated security email, so replies are not monitored.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
