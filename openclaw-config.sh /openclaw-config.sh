#!/bin/bash

# OpenClaw 配置管理工具
# 支持 OpenClaw 和 ClawdBot 两种版本
# 兼容 OpenAI 和 Anthropic 提供商

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
CONFIG_FILE=""
CONFIG_DIR=""
BACKUP_DIR=""
VERSION_NAME=""
CURRENT_USER=$(whoami)
HOME_DIR="/Users/$CURRENT_USER"

# 打印带颜色的消息
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# 显示 Logo
show_logo() {
    echo -e "${CYAN}"
    cat << 'EOF'
   ___                    ____ _                 
  / _ \ _ __   ___ _ __  / ___| | __ ___      __ 
 | | | | '_ \ / _ \ '_ \| |   | |/ _` \ \ /\ / / 
 | |_| | |_) |  __/ | | | |___| | (_| |\ V  V /  
  \___/| .__/ \___|_| |_|\____|_|\__,_| \_/\_/   
       |_|                                       
    配置管理工具 v1.0
EOF
    echo -e "${NC}"
}

# 检测已安装的版本
detect_version() {
    local openclaw_config="$HOME_DIR/.openclaw/openclaw.json"
    local clawdbot_config="$HOME_DIR/.clawdbot/clawdbot.json"
    
    local found_versions=()
    
    if [[ -f "$openclaw_config" ]]; then
        found_versions+=("openclaw")
    fi
    
    if [[ -f "$clawdbot_config" ]]; then
        found_versions+=("clawdbot")
    fi
    
    if [[ ${#found_versions[@]} -eq 0 ]]; then
        print_warning "未检测到已安装的配置文件"
        echo ""
        echo "请选择要创建的配置类型："
        echo "  1) OpenClaw ($HOME_DIR/.openclaw/)"
        echo "  2) ClawdBot ($HOME_DIR/.clawdbot/)"
        echo ""
        read -p "请选择 [1-2]: " choice
        case $choice in
            1)
                VERSION_NAME="openclaw"
                CONFIG_DIR="$HOME_DIR/.openclaw"
                CONFIG_FILE="$CONFIG_DIR/openclaw.json"
                ;;
            2)
                VERSION_NAME="clawdbot"
                CONFIG_DIR="$HOME_DIR/.clawdbot"
                CONFIG_FILE="$CONFIG_DIR/clawdbot.json"
                ;;
            *)
                print_error "无效选择"
                exit 1
                ;;
        esac
        mkdir -p "$CONFIG_DIR"
        create_default_config
    elif [[ ${#found_versions[@]} -eq 1 ]]; then
        VERSION_NAME="${found_versions[0]}"
        if [[ "$VERSION_NAME" == "openclaw" ]]; then
            CONFIG_DIR="$HOME_DIR/.openclaw"
            CONFIG_FILE="$CONFIG_DIR/openclaw.json"
        else
            CONFIG_DIR="$HOME_DIR/.clawdbot"
            CONFIG_FILE="$CONFIG_DIR/clawdbot.json"
        fi
        print_success "检测到 $VERSION_NAME 配置"
    else
        echo ""
        echo "检测到多个版本的配置文件："
        echo "  1) OpenClaw ($openclaw_config)"
        echo "  2) ClawdBot ($clawdbot_config)"
        echo ""
        read -p "请选择要管理的配置 [1-2]: " choice
        case $choice in
            1)
                VERSION_NAME="openclaw"
                CONFIG_DIR="$HOME_DIR/.openclaw"
                CONFIG_FILE="$CONFIG_DIR/openclaw.json"
                ;;
            2)
                VERSION_NAME="clawdbot"
                CONFIG_DIR="$HOME_DIR/.clawdbot"
                CONFIG_FILE="$CONFIG_DIR/clawdbot.json"
                ;;
            *)
                print_error "无效选择"
                exit 1
                ;;
        esac
    fi
    
    BACKUP_DIR="$CONFIG_DIR/backups"
    mkdir -p "$BACKUP_DIR"
}

# 创建默认配置
create_default_config() {
    local current_date=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    cat > "$CONFIG_FILE" << EOF
{
  "meta": {
    "lastTouchedVersion": "1.0.0",
    "lastTouchedAt": "$current_date"
  },
  "models": {
    "providers": {}
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "",
        "fallbacks": []
      },
      "models": {},
      "workspace": "$CONFIG_DIR/workspace",
      "maxConcurrent": 4
    }
  }
}
EOF
    print_success "已创建默认配置文件"
}

# 检查 jq 是否安装
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        print_error "需要安装 jq 工具"
        echo "请运行: brew install jq"
        exit 1
    fi
}

# 读取配置
read_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    else
        echo "{}"
    fi
}

# 保存配置
save_config() {
    local config="$1"
    local current_date=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    echo "$config" | jq --arg date "$current_date" '.meta.lastTouchedAt = $date' > "$CONFIG_FILE"
    print_success "配置已保存"
}

# 显示主菜单
show_main_menu() {
    clear
    show_logo
    print_header
    echo -e "${GREEN}当前配置:${NC} $CONFIG_FILE"
    echo -e "${GREEN}版本:${NC} $VERSION_NAME"
    print_header
    echo ""
    echo "  1) 📋 查看当前配置"
    echo "  2) 🔌 管理接入点 (Providers)"
    echo "  3) 🔑 管理密钥"
    echo "  4) 🤖 设置主力模型"
    echo "  5) 🔄 设置备用模型"
    echo "  6) 📦 一键备份"
    echo "  7) 🔄 一键重置"
    echo "  8) 📂 查看/恢复备份"
    echo "  9) ⚙️  高级设置"
    echo "  0) 🚪 退出"
    echo ""
    print_header
}

# 查看当前配置
view_config() {
    clear
    print_header
    echo -e "${CYAN}当前配置内容:${NC}"
    print_header
    echo ""
    
    local config=$(read_config)
    
    # 显示提供商信息
    echo -e "${YELLOW}【接入点配置】${NC}"
    local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
    if [[ -z "$providers" ]]; then
        echo "  暂无配置的接入点"
    else
        for provider in $providers; do
            local base_url=$(echo "$config" | jq -r ".models.providers[\"$provider\"].baseUrl // \"未设置\"")
            local api_key=$(echo "$config" | jq -r ".models.providers[\"$provider\"].apiKey // \"未设置\"")
            local masked_key="${api_key:0:10}...${api_key: -4}"
            local model_count=$(echo "$config" | jq ".models.providers[\"$provider\"].models // [] | length")
            
            echo -e "  ${GREEN}$provider${NC}"
            echo "    Base URL: $base_url"
            echo "    API Key: $masked_key"
            echo "    模型数量: $model_count"
            echo ""
        done
    fi
    
    # 显示模型配置
    echo -e "${YELLOW}【模型配置】${NC}"
    local primary=$(echo "$config" | jq -r '.agents.defaults.model.primary // "未设置"')
    echo "  主力模型: $primary"
    
    local fallbacks=$(echo "$config" | jq -r '.agents.defaults.model.fallbacks // [] | join(", ")')
    if [[ -z "$fallbacks" ]]; then
        echo "  备用模型: 未设置"
    else
        echo "  备用模型: $fallbacks"
    fi
    
    echo ""
    read -p "按回车键返回..." _
}

# 管理接入点菜单
manage_providers_menu() {
    while true; do
        clear
        print_header
        echo -e "${CYAN}接入点管理${NC}"
        print_header
        echo ""
        echo "  1) 添加 OpenAI 兼容接入点"
        echo "  2) 添加 Anthropic 接入点"
        echo "  3) 查看所有接入点"
        echo "  4) 删除接入点"
        echo "  5) 编辑接入点"
        echo "  0) 返回主菜单"
        echo ""
        
        read -p "请选择 [0-5]: " choice
        case $choice in
            1) add_openai_provider ;;
            2) add_anthropic_provider ;;
            3) list_providers ;;
            4) delete_provider ;;
            5) edit_provider ;;
            0) return ;;
            *) print_error "无效选择" ;;
        esac
    done
}

# 添加 OpenAI 兼容接入点
add_openai_provider() {
    clear
    print_header
    echo -e "${CYAN}添加 OpenAI 兼容接入点${NC}"
    print_header
    echo ""
    
    read -p "接入点名称 (例如: openai, deepseek, qwen): " provider_name
    if [[ -z "$provider_name" ]]; then
        print_error "名称不能为空"
        read -p "按回车键继续..." _
        return
    fi
    
    read -p "Base URL (例如: https://api.openai.com/v1): " base_url
    read -p "API Key: " api_key
    
    echo ""
    echo "是否添加预设模型？"
    echo "  1) 添加自定义模型"
    echo "  2) 使用 GPT 系列预设"
    echo "  3) 使用 DeepSeek 预设"
    echo "  4) 跳过，稍后添加"
    read -p "请选择 [1-4]: " model_choice
    
    local models="[]"
    case $model_choice in
        1)
            models=$(add_custom_models "openai-completions")
            ;;
        2)
            models='[
                {"id":"gpt-4o","name":"GPT-4o","api":"openai-completions","reasoning":false,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":16384},
                {"id":"gpt-4o-mini","name":"GPT-4o Mini","api":"openai-completions","reasoning":false,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":16384},
                {"id":"gpt-4-turbo","name":"GPT-4 Turbo","api":"openai-completions","reasoning":false,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":4096}
            ]'
            ;;
        3)
            models='[
                {"id":"deepseek-chat","name":"DeepSeek Chat","api":"openai-completions","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":64000,"maxTokens":8192},
                {"id":"deepseek-coder","name":"DeepSeek Coder","api":"openai-completions","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":64000,"maxTokens":8192},
                {"id":"deepseek-reasoner","name":"DeepSeek Reasoner","api":"openai-completions","reasoning":true,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":64000,"maxTokens":8192}
            ]'
            ;;
    esac
    
    local config=$(read_config)
    config=$(echo "$config" | jq \
        --arg name "$provider_name" \
        --arg url "$base_url" \
        --arg key "$api_key" \
        --argjson models "$models" \
        '.models.providers[$name] = {
            "baseUrl": $url,
            "apiKey": $key,
            "api": "openai-completions",
            "models": $models
        }')
    
    save_config "$config"
    
    # 添加模型别名
    add_model_aliases "$provider_name" "$models"
    
    print_success "接入点 $provider_name 添加成功"
    read -p "按回车键继续..." _
}

# 添加 Anthropic 接入点
add_anthropic_provider() {
    clear
    print_header
    echo -e "${CYAN}添加 Anthropic 接入点${NC}"
    print_header
    echo ""
    
    read -p "接入点名称 (默认: anthropic): " provider_name
    provider_name=${provider_name:-anthropic}
    
    read -p "Base URL (默认: https://api.anthropic.com): " base_url
    base_url=${base_url:-https://api.anthropic.com}
    
    read -p "API Key: " api_key
    
    echo ""
    echo "是否添加预设模型？"
    echo "  1) 添加自定义模型"
    echo "  2) 使用 Claude 系列预设"
    echo "  3) 跳过，稍后添加"
    read -p "请选择 [1-3]: " model_choice
    
    local models="[]"
    case $model_choice in
        1)
            models=$(add_custom_models "anthropic-messages")
            ;;
        2)
            models='[
                {"id":"claude-sonnet-4-20250514","name":"Claude Sonnet 4","api":"anthropic-messages","reasoning":true,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":200000,"maxTokens":64000},
                {"id":"claude-3-5-sonnet-20241022","name":"Claude 3.5 Sonnet","api":"anthropic-messages","reasoning":false,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":200000,"maxTokens":8192},
                {"id":"claude-3-5-haiku-20241022","name":"Claude 3.5 Haiku","api":"anthropic-messages","reasoning":false,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":200000,"maxTokens":8192},
                {"id":"claude-3-opus-20240229","name":"Claude 3 Opus","api":"anthropic-messages","reasoning":false,"input":["text","image"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":200000,"maxTokens":4096}
            ]'
            ;;
    esac
    
    local config=$(read_config)
    config=$(echo "$config" | jq \
        --arg name "$provider_name" \
        --arg url "$base_url" \
        --arg key "$api_key" \
        --argjson models "$models" \
        '.models.providers[$name] = {
            "baseUrl": $url,
            "apiKey": $key,
            "models": $models
        }')
    
    save_config "$config"
    
    # 添加模型别名
    add_model_aliases "$provider_name" "$models"
    
    print_success "接入点 $provider_name 添加成功"
    read -p "按回车键继续..." _
}

# 添加自定义模型
add_custom_models() {
    local api_type="$1"
    local models="[]"
    
    while true; do
        echo ""
        read -p "模型 ID (留空结束): " model_id
        if [[ -z "$model_id" ]]; then
            break
        fi
        
        read -p "模型显示名称: " model_name
        model_name=${model_name:-$model_id}
        
        read -p "是否支持推理 (y/n, 默认n): " reasoning
        reasoning=${reasoning:-n}
        [[ "$reasoning" == "y" ]] && reasoning="true" || reasoning="false"
        
        read -p "是否支持图片输入 (y/n, 默认n): " image_support
        image_support=${image_support:-n}
        if [[ "$image_support" == "y" ]]; then
            input='["text","image"]'
        else
            input='["text"]'
        fi
        
        read -p "上下文窗口大小 (默认128000): " context_window
        context_window=${context_window:-128000}
        
        read -p "最大输出 Token (默认8192): " max_tokens
        max_tokens=${max_tokens:-8192}
        
        models=$(echo "$models" | jq \
            --arg id "$model_id" \
            --arg name "$model_name" \
            --arg api "$api_type" \
            --argjson reasoning "$reasoning" \
            --argjson input "$input" \
            --argjson context "$context_window" \
            --argjson max "$max_tokens" \
            '. + [{
                "id": $id,
                "name": $name,
                "api": $api,
                "reasoning": $reasoning,
                "input": $input,
                "cost": {"input":0,"output":0,"cacheRead":0,"cacheWrite":0},
                "contextWindow": $context,
                "maxTokens": $max
            }]')
        
        print_success "模型 $model_id 已添加"
    done
    
    echo "$models"
}

# 添加模型别名
add_model_aliases() {
    local provider="$1"
    local models="$2"
    local config=$(read_config)
    
    local model_ids=$(echo "$models" | jq -r '.[].id')
    for model_id in $model_ids; do
        local full_id="$provider/$model_id"
        local alias=$(echo "$model_id" | sed 's/-[0-9]*$//' | tr '[:upper:]' '[:lower:]')
        
        config=$(echo "$config" | jq \
            --arg full_id "$full_id" \
            --arg alias "$alias" \
            '.agents.defaults.models[$full_id] = {"alias": $alias}')
    done
    
    save_config "$config"
}

# 列出所有接入点
list_providers() {
    clear
    print_header
    echo -e "${CYAN}所有接入点${NC}"
    print_header
    echo ""
    
    local config=$(read_config)
    local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
    
    if [[ -z "$providers" ]]; then
        echo "暂无配置的接入点"
    else
        local index=1
        for provider in $providers; do
            local base_url=$(echo "$config" | jq -r ".models.providers[\"$provider\"].baseUrl")
            local api=$(echo "$config" | jq -r ".models.providers[\"$provider\"].api // \"anthropic-messages\"")
            local model_count=$(echo "$config" | jq ".models.providers[\"$provider\"].models | length")
            
            echo -e "${GREEN}$index. $provider${NC}"
            echo "   URL: $base_url"
            echo "   API: $api"
            echo "   模型数: $model_count"
            
            # 列出模型
            local model_names=$(echo "$config" | jq -r ".models.providers[\"$provider\"].models[].name")
            if [[ -n "$model_names" ]]; then
                echo "   模型列表:"
                echo "$model_names" | while read name; do
                    echo "     - $name"
                done
            fi
            echo ""
            ((index++))
        done
    fi
    
    read -p "按回车键返回..." _
}

# 删除接入点
delete_provider() {
    clear
    print_header
    echo -e "${CYAN}删除接入点${NC}"
    print_header
    echo ""
    
    local config=$(read_config)
    local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
    
    if [[ -z "$providers" ]]; then
        echo "暂无可删除的接入点"
        read -p "按回车键返回..." _
        return
    fi
    
    echo "可用接入点:"
    local index=1
    declare -a provider_array
    for provider in $providers; do
        echo "  $index) $provider"
        provider_array[$index]=$provider
        ((index++))
    done
    echo ""
    
    read -p "请选择要删除的接入点编号 (0取消): " choice
    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        return
    fi
    
    local selected="${provider_array[$choice]}"
    if [[ -z "$selected" ]]; then
        print_error "无效选择"
        read -p "按回车键继续..." _
        return
    fi
    
    read -p "确认删除 $selected? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        config=$(echo "$config" | jq "del(.models.providers[\"$selected\"])")
        save_config "$config"
        print_success "接入点 $selected 已删除"
    fi
    
    read -p "按回车键继续..." _
}

# 编辑接入点
edit_provider() {
    clear
    print_header
    echo -e "${CYAN}编辑接入点${NC}"
    print_header
    echo ""
    
    local config=$(read_config)
    local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
    
    if [[ -z "$providers" ]]; then
        echo "暂无可编辑的接入点"
        read -p "按回车键返回..." _
        return
    fi
    
    echo "可用接入点:"
    local index=1
    declare -a provider_array
    for provider in $providers; do
        echo "  $index) $provider"
        provider_array[$index]=$provider
        ((index++))
    done
    echo ""
    
    read -p "请选择要编辑的接入点编号 (0取消): " choice
    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        return
    fi
    
    local selected="${provider_array[$choice]}"
    if [[ -z "$selected" ]]; then
        print_error "无效选择"
        read -p "按回车键继续..." _
        return
    fi
    
    local current_url=$(echo "$config" | jq -r ".models.providers[\"$selected\"].baseUrl")
    local current_key=$(echo "$config" | jq -r ".models.providers[\"$selected\"].apiKey")
    
    echo ""
    echo "当前 Base URL: $current_url"
    read -p "新 Base URL (留空保持不变): " new_url
    new_url=${new_url:-$current_url}
    
    echo ""
    echo "当前 API Key: ${current_key:0:10}..."
    read -p "新 API Key (留空保持不变): " new_key
    new_key=${new_key:-$current_key}
    
    config=$(echo "$config" | jq \
        --arg name "$selected" \
        --arg url "$new_url" \
        --arg key "$new_key" \
        '.models.providers[$name].baseUrl = $url | .models.providers[$name].apiKey = $key')
    
    save_config "$config"
    print_success "接入点 $selected 已更新"
    read -p "按回车键继续..." _
}

# 管理密钥
manage_api_keys() {
    clear
    print_header
    echo -e "${CYAN}密钥管理${NC}"
    print_header
    echo ""
    
    local config=$(read_config)
    local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
    
    if [[ -z "$providers" ]]; then
        echo "暂无配置的接入点"
        read -p "按回车键返回..." _
        return
    fi
    
    echo "选择要修改密钥的接入点:"
    local index=1
    declare -a provider_array
    for provider in $providers; do
        local current_key=$(echo "$config" | jq -r ".models.providers[\"$provider\"].apiKey")
        local masked_key="${current_key:0:10}...${current_key: -4}"
        echo "  $index) $provider (当前: $masked_key)"
        provider_array[$index]=$provider
        ((index++))
    done
    echo ""
    
    read -p "请选择 (0取消): " choice
    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        return
    fi
    
    local selected="${provider_array[$choice]}"
    if [[ -z "$selected" ]]; then
        print_error "无效选择"
        read -p "按回车键继续..." _
        return
    fi
    
    read -p "请输入新的 API Key: " new_key
    if [[ -z "$new_key" ]]; then
        print_error "密钥不能为空"
        read -p "按回车键继续..." _
        return
    fi
    
    config=$(echo "$config" | jq \
        --arg name "$selected" \
        --arg key "$new_key" \
        '.models.providers[$name].apiKey = $key')
    
    save_config "$config"
    print_success "接入点 $selected 的密钥已更新"
    read -p "按回车键继续..." _
}

# 设置主力模型
set_primary_model() {
    clear
    print_header
    echo -e "${CYAN}设置主力模型${NC}"
    print_header
    echo ""
    
    local config=$(read_config)
    local current_primary=$(echo "$config" | jq -r '.agents.defaults.model.primary // "未设置"')
    echo "当前主力模型: $current_primary"
    echo ""
    
    # 获取所有可用模型
    echo "可用模型:"
    local index=1
    declare -a model_array
    
    local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
    for provider in $providers; do
        local model_ids=$(echo "$config" | jq -r ".models.providers[\"$provider\"].models[].id")
        for model_id in $model_ids; do
            local full_id="$provider/$model_id"
            local model_name=$(echo "$config" | jq -r ".models.providers[\"$provider\"].models[] | select(.id==\"$model_id\") | .name")
            echo "  $index) $full_id ($model_name)"
            model_array[$index]=$full_id
            ((index++))
        done
    done
    
    if [[ $index -eq 1 ]]; then
        echo "  暂无可用模型，请先添加接入点"
        read -p "按回车键返回..." _
        return
    fi
    
    echo ""
    read -p "请选择主力模型编号 (0取消): " choice
    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        return
    fi
    
    local selected="${model_array[$choice]}"
    if [[ -z "$selected" ]]; then
        print_error "无效选择"
        read -p "按回车键继续..." _
        return
    fi
    
    config=$(echo "$config" | jq --arg model "$selected" '.agents.defaults.model.primary = $model')
    save_config "$config"
    
    print_success "主力模型已设置为: $selected"
    read -p "按回车键继续..." _
}

# 设置备用模型
set_fallback_models() {
    clear
    print_header
    echo -e "${CYAN}设置备用模型${NC}"
    print_header
    echo ""
    
    local config=$(read_config)
    local current_fallbacks=$(echo "$config" | jq -r '.agents.defaults.model.fallbacks // [] | join(", ")')
    echo "当前备用模型: ${current_fallbacks:-无}"
    echo ""
    
    echo "1) 添加备用模型"
    echo "2) 清空所有备用模型"
    echo "3) 重新设置备用模型"
    echo "0) 返回"
    echo ""
    
    read -p "请选择: " action
    
    case $action in
        1)
            # 获取所有可用模型
            echo ""
            echo "可用模型:"
            local index=1
            declare -a model_array
            
            local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
            for provider in $providers; do
                local model_ids=$(echo "$config" | jq -r ".models.providers[\"$provider\"].models[].id")
                for model_id in $model_ids; do
                    local full_id="$provider/$model_id"
                    echo "  $index) $full_id"
                    model_array[$index]=$full_id
                    ((index++))
                done
            done
            
            if [[ $index -eq 1 ]]; then
                echo "  暂无可用模型"
                read -p "按回车键返回..." _
                return
            fi
            
            echo ""
            read -p "请输入模型编号 (多个用空格分隔): " -a choices
            
            local new_fallbacks="[]"
            for choice in "${choices[@]}"; do
                local selected="${model_array[$choice]}"
                if [[ -n "$selected" ]]; then
                    new_fallbacks=$(echo "$new_fallbacks" | jq --arg m "$selected" '. + [$m]')
                fi
            done
            
            # 合并现有的备用模型
            local existing=$(echo "$config" | jq '.agents.defaults.model.fallbacks // []')
            local merged=$(echo "$existing $new_fallbacks" | jq -s 'add | unique')
            
            config=$(echo "$config" | jq --argjson fb "$merged" '.agents.defaults.model.fallbacks = $fb')
            save_config "$config"
            print_success "备用模型已更新"
            ;;
        2)
            config=$(echo "$config" | jq '.agents.defaults.model.fallbacks = []')
            save_config "$config"
            print_success "备用模型已清空"
            ;;
        3)
            echo ""
            echo "可用模型:"
            local index=1
            declare -a model_array
            
            local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
            for provider in $providers; do
                local model_ids=$(echo "$config" | jq -r ".models.providers[\"$provider\"].models[].id")
                for model_id in $model_ids; do
                    local full_id="$provider/$model_id"
                    echo "  $index) $full_id"
                    model_array[$index]=$full_id
                    ((index++))
                done
            done
            
            if [[ $index -eq 1 ]]; then
                echo "  暂无可用模型"
                read -p "按回车键返回..." _
                return
            fi
            
            echo ""
            read -p "请输入备用模型编号 (多个用空格分隔, 按优先级排序): " -a choices
            
            local new_fallbacks="[]"
            for choice in "${choices[@]}"; do
                local selected="${model_array[$choice]}"
                if [[ -n "$selected" ]]; then
                    new_fallbacks=$(echo "$new_fallbacks" | jq --arg m "$selected" '. + [$m]')
                fi
            done
            
            config=$(echo "$config" | jq --argjson fb "$new_fallbacks" '.agents.defaults.model.fallbacks = $fb')
            save_config "$config"
            print_success "备用模型已重新设置"
            ;;
        0)
            return
            ;;
    esac
    
    read -p "按回车键继续..." _
}

# 一键备份
backup_config() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/config_backup_$timestamp.json"
    
    cp "$CONFIG_FILE" "$backup_file"
    print_success "配置已备份到: $backup_file"
    read -p "按回车键继续..." _
}

# 一键重置
reset_config() {
    clear
    print_header
    echo -e "${RED}⚠️  警告：一键重置${NC}"
    print_header
    echo ""
    echo "此操作将:"
    echo "  1. 备份当前配置"
    echo "  2. 重置为默认配置"
    echo ""
    read -p "确认要重置配置吗? (输入 YES 确认): " confirm
    
    if [[ "$confirm" == "YES" ]]; then
        # 先备份
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="$BACKUP_DIR/config_before_reset_$timestamp.json"
        cp "$CONFIG_FILE" "$backup_file"
        print_info "已备份到: $backup_file"
        
        # 创建新配置
        create_default_config
        print_success "配置已重置"
    else
        print_info "操作已取消"
    fi
    
    read -p "按回车键继续..." _
}

# 查看/恢复备份
manage_backups() {
    clear
    print_header
    echo -e "${CYAN}备份管理${NC}"
    print_header
    echo ""
    
    local backups=$(ls -1 "$BACKUP_DIR"/*.json 2>/dev/null)
    
    if [[ -z "$backups" ]]; then
        echo "暂无备份文件"
        read -p "按回车键返回..." _
        return
    fi
    
    echo "可用备份:"
    local index=1
    declare -a backup_array
    for backup in $backups; do
        local filename=$(basename "$backup")
        local filesize=$(ls -lh "$backup" | awk '{print $5}')
        local filedate=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$backup" 2>/dev/null || stat --format="%y" "$backup" 2>/dev/null | cut -d. -f1)
        echo "  $index) $filename ($filesize, $filedate)"
        backup_array[$index]=$backup
        ((index++))
    done
    
    echo ""
    echo "操作:"
    echo "  r) 恢复备份"
    echo "  d) 删除备份"
    echo "  0) 返回"
    echo ""
    
    read -p "请选择操作: " action
    
    case $action in
        r)
            read -p "请输入要恢复的备份编号: " choice
            local selected="${backup_array[$choice]}"
            if [[ -n "$selected" ]]; then
                # 先备份当前配置
                local timestamp=$(date +"%Y%m%d_%H%M%S")
                cp "$CONFIG_FILE" "$BACKUP_DIR/config_before_restore_$timestamp.json"
                
                cp "$selected" "$CONFIG_FILE"
                print_success "配置已从备份恢复"
            else
                print_error "无效选择"
            fi
            ;;
        d)
            read -p "请输入要删除的备份编号: " choice
            local selected="${backup_array[$choice]}"
            if [[ -n "$selected" ]]; then
                rm "$selected"
                print_success "备份已删除"
            else
                print_error "无效选择"
            fi
            ;;
    esac
    
    read -p "按回车键继续..." _
}

# 高级设置菜单
advanced_settings() {
    while true; do
        clear
        print_header
        echo -e "${CYAN}高级设置${NC}"
        print_header
        echo ""
        echo "  1) 编辑工作空间路径"
        echo "  2) 设置最大并发数"
        echo "  3) 管理模型别名"
        echo "  4) 直接编辑配置文件"
        echo "  5) 验证配置文件"
        echo "  0) 返回主菜单"
        echo ""
        
        read -p "请选择 [0-5]: " choice
        case $choice in
            1) edit_workspace ;;
            2) set_max_concurrent ;;
            3) manage_aliases ;;
            4) edit_config_directly ;;
            5) validate_config ;;
            0) return ;;
            *) print_error "无效选择" ;;
        esac
    done
}

# 编辑工作空间路径
edit_workspace() {
    local config=$(read_config)
    local current=$(echo "$config" | jq -r '.agents.defaults.workspace // "未设置"')
    
    echo ""
    echo "当前工作空间: $current"
    read -p "新工作空间路径 (留空保持不变): " new_path
    
    if [[ -n "$new_path" ]]; then
        mkdir -p "$new_path"
        config=$(echo "$config" | jq --arg path "$new_path" '.agents.defaults.workspace = $path')
        save_config "$config"
        print_success "工作空间已更新"
    fi
    
    read -p "按回车键继续..." _
}

# 设置最大并发数
set_max_concurrent() {
    local config=$(read_config)
    local current=$(echo "$config" | jq -r '.agents.defaults.maxConcurrent // 4')
    
    echo ""
    echo "当前最大并发数: $current"
    read -p "新的最大并发数 (1-16): " new_value
    
    if [[ "$new_value" =~ ^[0-9]+$ ]] && [[ "$new_value" -ge 1 ]] && [[ "$new_value" -le 16 ]]; then
        config=$(echo "$config" | jq --argjson val "$new_value" '.agents.defaults.maxConcurrent = $val')
        save_config "$config"
        print_success "最大并发数已更新为 $new_value"
    else
        print_error "无效值，请输入 1-16 之间的数字"
    fi
    
    read -p "按回车键继续..." _
}

# 管理模型别名
manage_aliases() {
    clear
    print_header
    echo -e "${CYAN}模型别名管理${NC}"
    print_header
    echo ""
    
    local config=$(read_config)
    local aliases=$(echo "$config" | jq -r '.agents.defaults.models // {} | to_entries[] | "\(.key): \(.value.alias)"')
    
    echo "当前别名配置:"
    if [[ -z "$aliases" ]]; then
        echo "  暂无别名配置"
    else
        echo "$aliases" | while read line; do
            echo "  $line"
        done
    fi
    
    echo ""
    echo "1) 添加/修改别名"
    echo "2) 删除别名"
    echo "0) 返回"
    echo ""
    
    read -p "请选择: " action
    
    case $action in
        1)
            # 显示可用模型
            echo ""
            echo "可用模型:"
            local index=1
            declare -a model_array
            
            local providers=$(echo "$config" | jq -r '.models.providers // {} | keys[]' 2>/dev/null)
            for provider in $providers; do
                local model_ids=$(echo "$config" | jq -r ".models.providers[\"$provider\"].models[].id")
                for model_id in $model_ids; do
                    local full_id="$provider/$model_id"
                    echo "  $index) $full_id"
                    model_array[$index]=$full_id
                    ((index++))
                done
            done
            
            read -p "请选择模型编号: " choice
            local selected="${model_array[$choice]}"
            if [[ -n "$selected" ]]; then
                read -p "请输入别名: " alias_name
                if [[ -n "$alias_name" ]]; then
                    config=$(echo "$config" | jq \
                        --arg id "$selected" \
                        --arg alias "$alias_name" \
                        '.agents.defaults.models[$id] = {"alias": $alias}')
                    save_config "$config"
                    print_success "别名已设置"
                fi
            fi
            ;;
        2)
            read -p "请输入要删除别名的模型 ID: " model_id
            config=$(echo "$config" | jq --arg id "$model_id" 'del(.agents.defaults.models[$id])')
            save_config "$config"
            print_success "别名已删除"
            ;;
    esac
    
    read -p "按回车键继续..." _
}

# 直接编辑配置文件
edit_config_directly() {
    local editor=${EDITOR:-nano}
    if command -v code &> /dev/null; then
        read -p "使用 VS Code 打开? (y/n, 默认n): " use_vscode
        if [[ "$use_vscode" == "y" ]]; then
            code "$CONFIG_FILE"
            return
        fi
    fi
    $editor "$CONFIG_FILE"
}

# 验证配置文件
validate_config() {
    echo ""
    print_info "正在验证配置文件..."
    
    if jq empty "$CONFIG_FILE" 2>/dev/null; then
        print_success "配置文件 JSON 格式有效"
        
        local config=$(read_config)
        
        # 检查必要字段
        local has_providers=$(echo "$config" | jq 'has("models") and .models | has("providers")')
        local has_agents=$(echo "$config" | jq 'has("agents")')
        
        if [[ "$has_providers" == "true" ]]; then
            print_success "✓ models.providers 存在"
        else
            print_warning "✗ models.providers 不存在"
        fi
        
        if [[ "$has_agents" == "true" ]]; then
            print_success "✓ agents 配置存在"
        else
            print_warning "✗ agents 配置不存在"
        fi
        
        # 检查主力模型是否有效
        local primary=$(echo "$config" | jq -r '.agents.defaults.model.primary // ""')
        if [[ -n "$primary" ]]; then
            local provider=$(echo "$primary" | cut -d'/' -f1)
            local model_id=$(echo "$primary" | cut -d'/' -f2)
            local model_exists=$(echo "$config" | jq --arg p "$provider" --arg m "$model_id" '.models.providers[$p].models[] | select(.id == $m) | .id' 2>/dev/null)
            
            if [[ -n "$model_exists" ]]; then
                print_success "✓ 主力模型 $primary 配置有效"
            else
                print_warning "✗ 主力模型 $primary 在提供商中未找到"
            fi
        fi
    else
        print_error "配置文件 JSON 格式无效"
    fi
    
    read -p "按回车键继续..." _
}

# 主函数
main() {
    check_dependencies
    detect_version
    
    while true; do
        show_main_menu
        read -p "请选择 [0-9]: " choice
        
        case $choice in
            1) view_config ;;
            2) manage_providers_menu ;;
            3) manage_api_keys ;;
            4) set_primary_model ;;
            5) set_fallback_models ;;
            6) backup_config ;;
            7) reset_config ;;
            8) manage_backups ;;
            9) advanced_settings ;;
            0)
                print_info "感谢使用！"
                exit 0
                ;;
            *)
                print_error "无效选择"
                sleep 1
                ;;
        esac
    done
}

# 运行主函数
main
