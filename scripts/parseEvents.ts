import {
  AddressLike,
  BytesLike,
  Interface,
  LogDescription,
  TransactionReceipt,
} from "ethers";

export function parseEvents(
  iface: Interface,
  receipt: TransactionReceipt
): (LogDescription | undefined | null)[] {
  return receipt.logs
    .map((log) => {
      try {
        const aLog = JSON.parse(JSON.stringify(log));
        return iface.parseLog(aLog);
      } catch (e) {
        return undefined;
      }
    })
    .filter((n: LogDescription | undefined | null) => n);
}
