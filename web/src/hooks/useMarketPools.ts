import { SupportedChain } from "@/lib/chains";
import { COLLATERAL_TOKENS } from "@/lib/config";
import { swaprGraphQLClient } from "@/lib/subgraph";
import { isUndefined } from "@/lib/utils";
import { useQuery } from "@tanstack/react-query";
import * as batshit from "@yornaath/batshit";
import memoize from "micro-memoize";
import { Address, formatUnits } from "viem";
import {
  GetDepositsQuery,
  GetEternalFarmingsQuery,
  GetPoolsQuery,
  OrderDirection,
  Pool_OrderBy,
  getSdk,
} from "./queries/gql-generated-swapr";

export interface PoolIncentive {
  reward: bigint;
  apr: number;
  rewardToken: Address;
  bonusRewardToken: Address;
  startTime: bigint;
  endTime: bigint;
}

export interface PoolInfo {
  id: Address;
  fee: number;
  token0: Address;
  token1: Address;
  incentives: PoolIncentive[];
}

function getPoolApr(_seerRewardPerDay: number /*, stakedTvl: number*/): number {
  /*const seerUsdPrice = 2; // TODO: get SEER price
  const stakedTvl = 10000; // TODO: get pool TVL
  const usdCoinsPerYear = seerRewardPerDay * 365 * seerUsdPrice
  const yearlyAPR = usdCoinsPerYear / stakedTvl * 100;
  return yearlyAPR;*/
  return 0;
}

function mapEternalFarming(eternalFarming: GetEternalFarmingsQuery["eternalFarmings"][0]): PoolIncentive {
  return {
    reward: BigInt(eternalFarming.reward),
    apr: getPoolApr(Number(formatUnits(BigInt(eternalFarming.reward), 17))),
    rewardToken: eternalFarming.rewardToken,
    bonusRewardToken: eternalFarming.bonusRewardToken,
    startTime: BigInt(eternalFarming.startTime),
    endTime: BigInt(eternalFarming.endTime),
  };
}

const eternalFarming = memoize((chainId: SupportedChain) => {
  return batshit.create({
    name: "eternalFarmings",
    fetcher: async (ids: Address[]) => {
      const algebraFarmingClient = swaprGraphQLClient(chainId, "algebrafarming");

      if (!algebraFarmingClient) {
        throw new Error("Subgraph not available");
      }

      const { eternalFarmings } = await getSdk(algebraFarmingClient).GetEternalFarmings({
        where: { pool_in: ids },
      });

      return eternalFarmings;
    },
    scheduler: batshit.windowScheduler(10),
    resolver: (eternalFarmings, poolId) => eternalFarmings.filter((eternalFarming) => eternalFarming.pool === poolId),
  });
});

const getPools = memoize((chainId: SupportedChain) => {
  return batshit.create({
    name: "getPools",
    fetcher: async (tokens: { token0: Address; token1: Address }[]) => {
      const algebraClient = swaprGraphQLClient(chainId, "algebra");

      if (!algebraClient) {
        throw new Error("Subgraph not available");
      }

      const { pools } = await getSdk(algebraClient).GetPools({
        where: {
          or: tokens.map((t) => ({ token0: t.token0.toLocaleLowerCase(), token1: t.token1.toLocaleLowerCase() })),
        },
        orderBy: Pool_OrderBy.TotalValueLockedUsd,
        orderDirection: OrderDirection.Desc,
      });

      return pools;
    },
    scheduler: batshit.windowScheduler(10),
    resolver: (pools, tokens) =>
      pools.filter(
        (p) => p.token0.id === tokens.token0.toLocaleLowerCase() && p.token1.id === tokens.token1.toLocaleLowerCase(),
      ),
  });
});

async function getPoolInfo(
  chainId: SupportedChain,
  outcomeToken: Address,
  collateralToken: Address,
): Promise<PoolInfo[]> {
  const [token0, token1] =
    outcomeToken > collateralToken ? [collateralToken, outcomeToken] : [outcomeToken, collateralToken];

  const pools = await getPools(chainId).fetch({ token0, token1 });

  return await Promise.all(
    pools.map(async (pool) => {
      const eternalFarmings = await eternalFarming(chainId).fetch(pool.id as Address);

      return {
        id: pool.id as Address,
        fee: Number(pool.fee),
        token0,
        token1,
        incentives: eternalFarmings.map((eternalFarming) => mapEternalFarming(eternalFarming)),
      };
    }),
  );
}

export async function getAllOutcomePools(chainId: SupportedChain): Promise<GetPoolsQuery["pools"] | undefined> {
  const algebraClient = swaprGraphQLClient(chainId, "algebra");

  if (!algebraClient) {
    throw new Error("Subgraph not available");
  }
  try {
    const { pools } = await getSdk(algebraClient).GetPools({
      where: { or: [{ token0_: { symbol: "sDAI" } }, { token1_: { symbol: "sDAI" } }] },
    });
    return pools;
  } catch (e) {
    console.log(e);
  }
}

export const useMarketPools = (chainId: SupportedChain, tokens?: Address[]) => {
  return useQuery<Array<PoolInfo[]> | undefined, Error>({
    enabled: tokens && tokens.length > 0,
    queryKey: ["useMarketPools", chainId, tokens],
    retry: false,
    queryFn: async () => {
      return await Promise.all(
        tokens!.map(async (outcomeToken) => {
          return getPoolInfo(chainId, outcomeToken, COLLATERAL_TOKENS[chainId].primary.address);
        }),
      );
    },
  });
};

export const useAllOutcomePools = (chainId: SupportedChain) => {
  return useQuery<Awaited<ReturnType<typeof getAllOutcomePools>>, Error>({
    queryKey: ["useAllOutcomePools", chainId],
    retry: false,
    queryFn: async () => await getAllOutcomePools(chainId),
  });
};

type PoolsDeposits = Record<Address, GetDepositsQuery["deposits"]>;

export const usePoolsDeposits = (chainId: SupportedChain, pools: Address[], owner?: Address) => {
  return useQuery<PoolsDeposits | undefined, Error>({
    queryKey: ["usePoolsDeposits", chainId, pools, owner],
    enabled: !!owner,
    queryFn: async () => {
      const algebraFarmingClient = swaprGraphQLClient(chainId, "algebrafarming");

      if (!algebraFarmingClient || pools.length === 0) {
        return {};
      }

      const { deposits } = await getSdk(algebraFarmingClient).GetDeposits({
        where: { pool_in: pools, owner, liquidity_not: "0" },
      });

      return deposits.reduce((acum, curr) => {
        if (isUndefined(acum[curr.pool])) {
          acum[curr.pool] = [];
        }

        acum[curr.pool].push(curr);

        return acum;
      }, {} as PoolsDeposits);
    },
  });
};
