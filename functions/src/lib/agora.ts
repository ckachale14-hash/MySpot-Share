import { RtcTokenBuilder, RtcRole } from "agora-token";

/**
 * Mint a short-lived Agora RTC token. The app certificate is a secret and lives
 * only here on the server; clients receive only the per-channel token.
 */
export function mintRtcToken(params: {
  appId: string;
  appCertificate: string;
  channel: string;
  uid: number;
  publisher: boolean;
  ttlSeconds?: number;
}): string {
  const ttl = params.ttlSeconds ?? 3600;
  const expire = Math.floor(Date.now() / 1000) + ttl;
  return RtcTokenBuilder.buildTokenWithUid(
    params.appId,
    params.appCertificate,
    params.channel,
    params.uid,
    params.publisher ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER,
    expire,
    expire
  );
}
