---
title: nodejs项目工程化：eslint+prettier+husky+lint-staged+ commitlint+commitizen
published: 2024-05-22
description: '使用eslint和prettier检查并格式化代码，使用husky规范git提交格式'
tags: ['eslint', 'prettier']
category: '技术'
draft: false 
---

## 初始化项目

使用`npm init vite@latest`创建项目，选择不使用框架，选择使用`typescript`。

## eslint

1. 输入`npm i -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin`安装相关依赖。

2. 在项目根目录下创建.eslintrc文件并写入一下内容

   ```javascript
   {
     // 该配置项主要用于指示此.eslintrc文件是Eslint在项目内使用的根级别文件，并且 ESLint 不应在该目录之外搜索配置文件
     "root": true,
   
     // 默认情况下，Eslint使用其内置的 Espree 解析器，该解析器与标准 JavaScript 运行时和版本兼容，而我们需要将ts代码解析为eslint兼容的AST，所以此处我们使用 @typescript-eslint/parser。
     "parser": "@typescript-eslint/parser",
   
     // 该配置项告诉eslint我们拓展了哪些指定的配置集，其中
     // eslint:recommended ：该配置集是 ESLint 内置的“推荐”，它打开一组小的、合理的规则，用于检查众所周知的最佳实践
     // @typescript-eslint/recommended：该配置集是typescript-eslint的推荐，它与eslint:recommended相似，但它启用了特定于ts的规则
     // @typescript-eslint/eslint-recommended ：该配置集禁用 eslint:recommended 配置集中已经由 typeScript 处理的规则，防止eslint和typescript之间的冲突。
     "extends": [
       "eslint:recommended",
       "plugin:@typescript-eslint/recommended",
       "plugin:@typescript-eslint/eslint-recommended",
     ],
   
     // 该配置项指示要加载的插件，这里
     // @typescript-eslint 插件使得我们能够在我们的存储库中使用typescript-eslint包定义的规则集。
     "plugins": ["@typescript-eslint"]
   } 
   ```

3. 在项目根目录创建.eslintignore文件并写入一下内容

   ```
   node_modules/
   
   package-lock.json
   ```

4. 在package.json中新增执行eslint的脚本

   ```json
   "scripts": {
       "lint": "eslint ./ --ext .ts,.js,.json --max-warnings=0"
   }
   ```

   此时在命令行运行`npm run lint`则会使用eslint规则检查代码了。

## prettier

1. 输入`npm i -D prettier`安装prettier。

2. 在项目根目录下创建.prettierrc文件，内容如下

   ```javascript
   {
     "semi": false,
     "singleQuote": true,
     "tabWidth": 2,
     "printWidth": 120
   }
   ```

3. 在项目根目录创建.prettierignore文件，内容如下

   ```
   node_modules/
   
   package-lock.json
   ```

4. 在package.json文件中增加如下命令

   ```json
   "scripts": {
       "format": "prettier --config .prettierrc . --write"
   }
   ```

   此时在命令行中运行`npm run format`就会按照配置的prettier规则自动格式化代码了。

   

## 解决eslint和prettier的代码风格冲突

1. 安装相关依赖`npm i -D eslint-config-prettier eslint-plugin-prettier`。

2. 在.eslintrc文件中加入新内容，整合后的完整内容如下

   ```javascript
   {
     // 该配置项主要用于指示此.eslintrc文件是Eslint在项目内使用的根级别文件，并且 ESLint 不应在该目录之外搜索配置文件
     "root": true,
   
     // 默认情况下，Eslint使用其内置的 Espree 解析器，该解析器与标准 JavaScript 运行时和版本兼容，而我们需要将ts代码解析为eslint兼容的AST，所以此处我们使用 @typescript-eslint/parser。
     "parser": "@typescript-eslint/parser",
   
     // 该配置项告诉eslint我们拓展了哪些指定的配置集，其中
     // eslint:recommended ：该配置集是 ESLint 内置的“推荐”，它打开一组小的、合理的规则，用于检查众所周知的最佳实践
     // @typescript-eslint/recommended：该配置集是typescript-eslint的推荐，它与eslint:recommended相似，但它启用了特定于ts的规则
     // @typescript-eslint/eslint-recommended ：该配置集禁用 eslint:recommended 配置集中已经由 typeScript 处理的规则，防止eslint和typescript之间的冲突。
     // prettier（即eslint-config-prettier）关闭所有可能干扰 Prettier 规则的 ESLint 规则，确保将其放在最后，这样它有机会覆盖其他配置集
     "extends": [
       "eslint:recommended",
       "plugin:@typescript-eslint/recommended",
       "plugin:@typescript-eslint/eslint-recommended",
       "prettier"
     ],
   
     // 该配置项指示要加载的插件，这里
     // @typescript-eslint 插件使得我们能够在我们的存储库中使用typescript-eslint包定义的规则集。
     // prettier插件（即eslint-plugin-prettier）将 Prettier 规则转换为 ESLint 规则
     "plugins": ["@typescript-eslint", "prettier"],
   
     "rules": {
       "prettier/prettier": "error", // 打开prettier插件提供的规则，该插件从 ESLint 内运行 Prettier
   
       // 关闭这两个 ESLint 核心规则，这两个规则和prettier插件一起使用会出现问题，具体可参阅
       // https://github.com/prettier/eslint-plugin-prettier/blob/master/README.md#arrow-body-style-and-prefer-arrow-callback-issue
       "arrow-body-style": "off",
       "prefer-arrow-callback": "off",
       "@typescript-eslint/no-explicit-any": "off"
     }
   }
   ```

   此时prettier已作为eslint的规则集使用了，运行`npm run lint`如果代码不符合prettier的规则也会报错。

## (可选)eslint引入vue3文件校验

1. 安装相关依赖`npm i -D vue-eslint-parser eslint-plugin-vue`。

2. 更改.eslintrc文件，更改后的完整代码如下

   ```javascript
   {
     // 该配置项主要用于指示此.eslintrc文件是Eslint在项目内使用的根级别文件，并且 ESLint 不应在该目录之外搜索配置文件
     "root": true,
   
     // 默认情况下，Eslint使用其内置的 Espree 解析器，该解析器与标准 JavaScript 运行时和版本兼容，而我们需要将ts代码解析为eslint兼容的AST，所以此处我们使用 @typescript-eslint/parser。
     "parser": "vue-eslint-parser",
     "parserOptions": {
       "ecmaVersion": "latest",
       "sourceType": "module",
       "parser": "@typescript-eslint/parser"
     },
   
     // 该配置项告诉eslint我们拓展了哪些指定的配置集，其中
     // eslint:recommended ：该配置集是 ESLint 内置的“推荐”，它打开一组小的、合理的规则，用于检查众所周知的最佳实践
     // @typescript-eslint/recommended：该配置集是typescript-eslint的推荐，它与eslint:recommended相似，但它启用了特定于ts的规则
     // @typescript-eslint/eslint-recommended ：该配置集禁用 eslint:recommended 配置集中已经由 typeScript 处理的规则，防止eslint和typescript之间的冲突。
     // prettier（即eslint-config-prettier）关闭所有可能干扰 Prettier 规则的 ESLint 规则，确保将其放在最后，这样它有机会覆盖其他配置集
     "extends": [
       "eslint:recommended",
       "plugin:@typescript-eslint/recommended",
       "plugin:@typescript-eslint/eslint-recommended",
       "plugin:vue/vue3-recommended",
       "prettier"
     ],
   
     // 该配置项指示要加载的插件，这里
     // @typescript-eslint 插件使得我们能够在我们的存储库中使用typescript-eslint包定义的规则集。
     // prettier插件（即eslint-plugin-prettier）将 Prettier 规则转换为 ESLint 规则
     "plugins": ["@typescript-eslint", "prettier"],
   
     "rules": {
       "prettier/prettier": "error", // 打开prettier插件提供的规则，该插件从 ESLint 内运行 Prettier
   
       // 关闭这两个 ESLint 核心规则，这两个规则和prettier插件一起使用会出现问题，具体可参阅
       // https://github.com/prettier/eslint-plugin-prettier/blob/master/README.md#arrow-body-style-and-prefer-arrow-callback-issue
       "arrow-body-style": "off",
       "prefer-arrow-callback": "off",
       "@typescript-eslint/no-explicit-any": "off"
     }
   }
   ```

3. 修改package.json文件，增加vue文件的校验

   ```json
   "scripts": {
       "lint": "eslint ./ --ext .ts,.js,.vue,.json --max-warnings=0", // 在原来的基础上增加.vue后缀
     },
   ```

   

## husky

1. 运行命令`npm i -D husky && npx husky install`安装并初始化husky。

2. 在package.json中新增一个命令

   ```json
   "scripts": {
       "prepare": "husky install",
   }
   ```

   这样在其他人克隆该项目并安装依赖时会自动通过husky启用git hook。

3. 通过husky命令创建pre-commit这个git hook`npx husky add .husky/pre-commit "npm run lint"`，设置在每次提交前运行`npm run lint`命令来检查代码，此时.husky/pre-commit文件中的内容应该如下所示

   ```bash
   #!/usr/bin/env sh
   . "$(dirname -- "$0")/_/husky.sh"
   
   npm run lint
   ```

   此时在每次git commit之前都会对代码进行eslint校验了，如不符合规则则会提交失败。

## lint-staged

1. 安装lint-staged`npm i -D lint-staged`。

2. 在项目根目录下创建.lintstagedrc.cjs文件，内容如下

   ```javascript
   const { ESLint } = require('eslint')
   
   const removeIgnoredFiles = async (files) => {
     const eslint = new ESLint()
     const ignoredFiles = await Promise.all(files.map((file) => eslint.isPathIgnored(file)))
     const filteredFiles = files.filter((_, i) => !ignoredFiles[i])
     return filteredFiles.join(' ')
   }
   
   module.exports = {
     '*': async (files) => {
       const filesToLint = await removeIgnoredFiles(files)
       return [`eslint ${filesToLint} --max-warnings=0`]
     }
   }
   ```

   这个配置的作用是对所有lint-staged检测到的文件，其中过滤掉忽略的文件，然后执行eslint脚本。

3. 修改.husky/pre-commit文件，将`npm run lint`更改为`npx lint-staged`。

## commitlint

1. 安装相关依赖`npm i -D @commitlint/cli @commitlint/config-conventional`。

2. 在项目根目录创建.commitlintrc.json，内容如下

   ```json
   {
     "extends": ["@commitlint/config-conventional"],
     "rules": {
       "scope-empty": [2, "never"]
     }
   }
   ```

3. 运行命令`npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'`，此时.husky/commit-msg文件的内容应该如下

   ```bash
   #!/usr/bin/env sh
   . "$(dirname -- "$0")/_/husky.sh"
   
   npx --no -- commitlint --edit "$1"
   
   ```

## commitizen

1. 安装相关依赖`npm i -D commitizen cz-conventional-changelog`。

2. 在项目根目录下创建.czrc文件，内容如下

   ```json
   {
     "path": "cz-conventional-changelog"
   }
   ```

3. 在package.json中增加如下命令

   ```json
   "scripts": {
       "cz": "cz",
   }
   ```

   此时运行命令`npm run cz`则可根据规则提交代码了。

## 总结

至此，配置完成，若项目使用了vue或react框架则自行在eslint配置中加入相应规则即可。

**2024-06-03 添加，今天发现antfu大佬的一个库`@antfu/eslint-config`，集成了所有的配置项，使用更简单，直接用这个库就行了。**

*参考资源：[bilibili](https://www.bilibili.com/video/BV1a8411i77L)*