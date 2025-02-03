#!/bin/bash
set -euo pipefail

#############################
# Kiểm tra biến môi trường bắt buộc
#############################
echo -e "\033[1;34mKiểm tra biến môi trường bắt buộc...\033[0m"
: "${DB_HOST:?Chưa thiết lập biến môi trường DB_HOST}"
: "${DB_USER:?Chưa thiết lập biến môi trường DB_USER}"
: "${DB_PASS:?Chưa thiết lập biến môi trường DB_PASS}"
: "${DB_NAME:?Chưa thiết lập biến môi trường DB_NAME}"

# Thư mục lưu backup, mặc định là /backup nếu không được truyền vào
BACKUP_DIR="${BACKUP_DIR:-/backup}"
mkdir -p "$BACKUP_DIR"

# Số ngày giữ file backup và số lượng file tối đa trước khi dọn dẹp
RETENTION_DAYS="${RETENTION_DAYS:-7}"
MAX_FILES="${MAX_FILES:-7}"

# Kiểm tra giá trị hợp lệ của RETENTION_DAYS và MAX_FILES
if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]] || [[ "$RETENTION_DAYS" -le 0 ]]; then
    echo -e "\033[1;31mGiá trị RETENTION_DAYS không hợp lệ. Phải là số nguyên dương.\033[0m" >&2
    exit 1
fi

if ! [[ "$MAX_FILES" =~ ^[0-9]+$ ]] || [[ "$MAX_FILES" -le 0 ]]; then
    echo -e "\033[1;31mGiá trị MAX_FILES không hợp lệ. Phải là số nguyên dương.\033[0m" >&2
    exit 1
fi

#############################
# Cấu hình Backup MySQL
#############################
echo -e "\033[1;34mCấu hình Backup MySQL...\033[0m"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
ZIP_FILE="$BACKUP_FILE.zip"

# Thực hiện backup database
echo -e "\033[1;33mThực hiện backup cơ sở dữ liệu...\033[0m"
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" >"$BACKUP_FILE"

# Kiểm tra file backup đã được tạo thành công chưa
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo -e "\033[1;31mBackup thất bại!\033[0m" >&2
    exit 1
fi

# Nén file backup với mật khẩu nếu có
if [[ -n "${BACKUP_PASSWORD:-}" ]]; then
    echo -e "\033[1;33mNén file backup với mật khẩu...\033[0m"
    zip -j -P "$BACKUP_PASSWORD" "$ZIP_FILE" "$BACKUP_FILE"
else
    echo -e "\033[1;33mNén file backup...\033[0m"
    zip -j "$ZIP_FILE" "$BACKUP_FILE"
fi

# Xóa file SQL gốc sau khi nén
rm -f "$BACKUP_FILE"

echo -e "\033[1;32mBackup thành công: $ZIP_FILE\033[0m"

#############################
# Tùy chọn: Upload lên S3 và dọn dẹp file cũ trên S3
#############################
if [[ -n "${S3_BUCKET:-}" ]]; then
    echo -e "\033[1;34mKiểm tra upload lên S3...\033[0m"
    # Kiểm tra các biến môi trường cần thiết cho S3
    : "${S3_URL:?Chưa thiết lập biến môi trường S3_URL khi S3_BUCKET được cấu hình}"
    : "${ACCESS_KEY:?Chưa thiết lập biến môi trường ACCESS_KEY khi S3_BUCKET được cấu hình}"
    : "${SECRET_KEY:?Chưa thiết lập biến môi trường SECRET_KEY khi S3_BUCKET được cấu hình}"
    # S3_PATH là biến tùy chọn, mặc định là 'mysql'
    S3_PATH="${S3_PATH:-mysql}"

    # Thiết lập alias mặc định cho MinIO Client
    mc alias set k8s-dbi "$S3_URL" "$ACCESS_KEY" "$SECRET_KEY"

    # Upload file backup lên S3
    mc cp "$ZIP_FILE" "k8s-dbi/$S3_BUCKET/$S3_PATH/"
    echo -e "\033[1;32mUpload thành công lên S3: k8s-dbi/$S3_BUCKET/$S3_PATH/$(basename "$ZIP_FILE")\033[0m"

    # Kiểm tra số lượng file trong thư mục backup trên S3
    FILE_COUNT=$(mc ls "k8s-dbi/$S3_BUCKET/$S3_PATH" | wc -l)
    if [[ "$FILE_COUNT" -gt "$MAX_FILES" ]]; then
        mc rm "k8s-dbi/$S3_BUCKET/$S3_PATH" --older-than ${RETENTION_DAYS}d
        echo -e "\033[1;33mDọn dẹp file backup cũ trên S3 hoàn tất.\033[0m"
    else
        echo -e "\033[1;32mSố lượng file backup trên S3 chưa vượt quá $MAX_FILES, không thực hiện dọn dẹp.\033[0m"
    fi
else
    echo -e "\033[1;33mBiến S3_BUCKET không được cấu hình, bỏ qua upload và dọn dẹp trên S3.\033[0m"
fi

#############################
# Dọn dẹp file backup cũ trên local storage
#############################
echo -e "\033[1;34mDọn dẹp file backup cũ trên local storage...\033[0m"
# Xóa các file backup cũ hơn RETENTION_DAYS ngày
find "$BACKUP_DIR" -type f -name "*.zip" -mtime +$RETENTION_DAYS -exec rm -f {} \;

# Kiểm tra số lượng file trong thư mục backup
LOCAL_FILE_COUNT=$(ls "$BACKUP_DIR"/*.zip 2>/dev/null | wc -l)
if [[ "$LOCAL_FILE_COUNT" -gt "$MAX_FILES" ]]; then
    # Dọn dẹp nếu số lượng file vượt quá MAX_FILES
    ls -t "$BACKUP_DIR"/*.zip | tail -n +$((MAX_FILES + 1)) | xargs rm -f
    echo -e "\033[1;33mDọn dẹp file backup cũ trên local hoàn tất.\033[0m"
else
    echo -e "\033[1;32mSố lượng file backup trên local chưa vượt quá $MAX_FILES, không thực hiện dọn dẹp.\033[0m"
fi
