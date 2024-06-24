import { executeCoWTrade } from "@/hooks/trade/executeCowTrade";
import { executeSwaprTrade } from "@/hooks/trade/executeSwaprTrade";
import { queryClient } from "@/lib/query-client";
import { Token } from "@/lib/tokens";
import {
  CoWTrade,
  Currency,
  Percent,
  SwaprV3Trade,
  Token as SwaprToken,
  TokenAmount,
  Trade,
  TradeType,
  WXDAI,
} from "@swapr/sdk";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Address, TransactionReceipt, parseUnits, zeroAddress } from "viem";
import { gnosis } from "viem/chains";
import { useGlobalState } from "../useGlobalState";
import { useMissingApprovals } from "../useMissingApprovals";

interface QuoteTradeResult {
  value: bigint;
  decimals: number;
  buyToken: Address;
  sellToken: Address;
  sellAmount: string;
  swapType: "buy" | "sell";
  trade: CoWTrade | SwaprV3Trade;
}

function getSwaprTrade(
  currencyIn: SwaprToken,
  currencyOut: SwaprToken,
  currencyAmountIn: TokenAmount,
  maximumSlippage: Percent,
  account: Address | undefined,
  chainId: number,
): Promise<SwaprV3Trade | null> {
  if (
    chainId === gnosis.id &&
    (currencyIn.address === WXDAI[chainId].address || currencyOut.address === WXDAI[chainId].address)
  ) {
    // build the route using the intermediate WXDAI<>sDAI pool
    const SDAI = new SwaprToken(chainId, "0xaf204776c7245bf4147c2612bf6e5972ee483701", 18, "sDAI");
    const path: Currency[] = [currencyIn, SDAI, currencyOut];

    return SwaprV3Trade.getQuoteWithPath({
      amount: currencyAmountIn,
      path,
      maximumSlippage,
      recipient: account || zeroAddress,
      tradeType: TradeType.EXACT_INPUT,
    });
  }

  return SwaprV3Trade.getQuote({
    amount: currencyAmountIn,
    quoteCurrency: currencyOut,
    maximumSlippage,
    recipient: account || zeroAddress,
    tradeType: TradeType.EXACT_INPUT,
  });
}

export function useQuoteTrade(
  chainId: number,
  account: Address | undefined,
  amount: string,
  outcomeToken: Token,
  collateralToken: Token,
  swapType: "buy" | "sell",
) {
  const [buyToken, sellToken] =
    swapType === "buy" ? [outcomeToken, collateralToken] : ([collateralToken, outcomeToken] as [Token, Token]);

  const sellAmount = parseUnits(String(amount), sellToken.decimals);

  return useQuery<QuoteTradeResult | undefined, Error>({
    queryKey: ["useQuoteTrade", chainId, account, amount.toString(), outcomeToken, collateralToken, swapType],
    enabled: sellAmount > 0n,
    retry: false,
    queryFn: async () => {
      const currencyIn = new SwaprToken(chainId, sellToken.address, sellToken.decimals, sellToken.symbol);
      const currencyOut = new SwaprToken(chainId, buyToken.address, buyToken.decimals, buyToken.symbol);

      const currencyAmountIn = new TokenAmount(currencyIn, parseUnits(String(amount), currencyIn.decimals));

      const maximumSlippage = new Percent("1", "100");

      const cowTradePromise = CoWTrade.bestTradeExactIn({
        currencyAmountIn,
        currencyOut,
        maximumSlippage,
        user: account || zeroAddress,
        receiver: account || zeroAddress,
      });

      const swaprTradePromise = getSwaprTrade(
        currencyIn,
        currencyOut,
        currencyAmountIn,
        maximumSlippage,
        account,
        chainId,
      );

      const [cow, swapr] = await Promise.allSettled([cowTradePromise, swaprTradePromise]);

      if (cow.status === "rejected" || swapr.status === "rejected") {
        throw new Error("No route found");
      }

      const trade = (cow?.value || swapr?.value)!;

      return {
        value: BigInt(trade.outputAmount.raw.toString()),
        decimals: sellToken.decimals,
        trade,
        buyToken: buyToken.address,
        sellToken: sellToken.address,
        sellAmount: sellAmount.toString(),
        swapType,
      };
    },
  });
}

export function useMissingTradeApproval(account: Address, trade: Trade) {
  const { data: missingApprovals } = useMissingApprovals(
    [trade.executionPrice.baseCurrency.address as `0x${string}`],
    account,
    trade.approveAddress as `0x${string}`,
    BigInt(trade.inputAmount.raw.toString()),
  );

  return missingApprovals;
}

async function tradeTokens({
  trade,
  account,
}: { trade: CoWTrade | SwaprV3Trade; account: Address }): Promise<string | TransactionReceipt> {
  if (trade instanceof CoWTrade) {
    return executeCoWTrade(trade);
  }

  return executeSwaprTrade(trade, account);
}

export function useTrade(onSuccess: () => unknown) {
  const { addPendingOrder } = useGlobalState();
  return useMutation({
    mutationFn: tradeTokens,
    onSuccess: (result: string | TransactionReceipt) => {
      if (typeof result === "string") {
        // cowswap order id
        addPendingOrder(result);
      }
      queryClient.invalidateQueries({ queryKey: ["useUserPositions"] });
      queryClient.invalidateQueries({ queryKey: ["useTokenBalance"] });
      onSuccess();
    },
  });
}
