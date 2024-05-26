# 使用 node:18 作为基础镜像进行构建阶段
FROM node:18 AS build

# 复制当前目录下的所有文件到容器的 /app 目录
COPY . /app

# 设置工作目录
WORKDIR /app

# 设置镜像源为腾讯云镜像源，加快依赖包下载速度
RUN yarn config set registry https://mirrors.cloud.tencent.com/npm/ && \
    yarn config set network-timeout 600000

# 安装依赖
# COPY package.json yarn.lock ./
# RUN yarn install
# 安装依赖并构建应用
RUN yarn install && yarn run build

# 构建 web 子项目
# WORKDIR /app/web
# COPY web/package.json web/yarn.lock ./
# RUN for i in {1..5}; do yarn install && break || sleep 15; done

# 构建 web 子项目
WORKDIR /app/web
RUN yarn install && yarn run build

# # 复制代码并构建
# COPY . /app
# RUN yarn run build

# 使用 node:18-alpine 作为基础镜像进行生产阶段
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装 dotenvx 环境变量管理工具
RUN curl -fsS https://dotenvx.sh/ | sh

# 复制环境变量文件和构建产物到生产镜像
COPY .env /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/src ./src
COPY --from=build /app/web/build ./web/build
COPY --from=build /app/package.json ./

# 设置镜像源为腾讯云镜像源，并仅安装生产依赖，然后清理 yarn 缓存
RUN yarn config set registry https://mirrors.cloud.tencent.com/npm/ && \
    yarn install --production && \
    yarn cache clean

# 暴露端口 3000
EXPOSE 3000

# 容器启动时执行的命令
CMD yarn run start
