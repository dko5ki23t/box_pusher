import argparse
import os

from common import Point, PointRectRange, PointDistanceRange

output_block_floor_default = 'config_block_floor_distribution.csv'
output_obj_in_block_default = 'config_obj_in_block_distribution.csv'

class BlocksPoints:
    block_num = 0
    points = []

    def __init__(self, block_num: int, points: list):
        self.block_num = block_num
        self.points = points

def set_argparse():
    parser = argparse.ArgumentParser(description='config_block_floor_map.csvとconfig_obj_in_block_map.csvから分布情報を作成する')
    parser.add_argument('block_floor', help='ステージ上範囲->ブロックと床の割合を記述したCSVファイル(config_block_floor_map.csv)')
    parser.add_argument('obj_in_block', help='ステージ上範囲->ブロック破壊時出現アイテムを記述したCSVファイル(config_obj_in_block.csv)')
    args = parser.parse_args()
    return args

def main():
    args = set_argparse()

    # ブロック/床の割合CSVファイル読み込み
    line_text = ["rangeType, point1X, point1Y, point2X, point2Y, distance, total, floorNone, floorWater, floorMagma, blockL1, blockL2, blockL3, blockL4\n"]
    line_count = 0
    calced_points = []
    blocks_info_list = []
    with open(args.block_floor, mode='r', encoding="utf-8") as file:
        for line in file:
            line_count += 1
            # 1行目と2行目は無視する
            if line_count <= 2:
                continue
            # 現在の行のカンマ区切りをリストに保存
            elements = line.split(',')
            # 範囲の種類
            range_type = elements[0]
            # その他パラメータ
            point1 = Point(int(elements[1]), int(elements[2]))
            point2 = Point(int(elements[3]), int(elements[4]))
            distance = int(elements[5])

            # 対象の範囲を定める
            if range_type == "rect":
                r = PointRectRange(point1, point2)
            elif range_type == "distance":
                r = PointDistanceRange(point1, distance)
            else:
                # エラー
                continue
            target_points = [p for p in r.get_list() if p not in calced_points]
            calced_points += target_points

            # 以下、出力する内容について
            output = []
            # 範囲
            for i in range(0, 6):
                output.append(elements[i])
            total = len(target_points)  # 総計
            output.append(total)
            output.append(round(total * int(elements[6]) * 0.01))       # 床
            output.append(round(total * int(elements[7]) * 0.01))       # 水
            output.append(round(total * int(elements[8]) * 0.01))       # マグマ
            output.append(round(total * int(elements[9]) * 0.01))       # ブロックLv.1
            output.append(round(total * int(elements[10]) * 0.01))      # ブロックLv.2
            output.append(round(total * int(elements[11]) * 0.01))      # ブロックLv.3
            output.append(round(total * int(elements[12]) * 0.01))      # ブロックLv.4
            blocks_info_list.append(BlocksPoints(sum(output[-4:]), target_points))
            line_text.append(','.join(map(str, output)) + '\n')
    
    # CSVファイルに書き込み
    with open(output_block_floor_default, mode='w', encoding="utf-8") as file:
        for text in line_text:
            file.write(text)

    # ブロック破壊時オブジェクトの割合CSVファイル読み込み
    line_text = ["rangeType, point1X, point1Y, point2X, point2Y, distance, total, jewels, obj1, level1, num1, obj2, level2, num2\n"]
    line_count = 0
    calced_points = []
    with open(args.obj_in_block, mode='r', encoding="utf-8") as file:
        for line in file:
            line_count += 1
            # 1行目と2行目は無視する
            if line_count <= 2:
                continue
            # 現在の行のカンマ区切りをリストに保存
            elements = line.split(',')
            # 範囲の種類
            range_type = elements[0]
            # その他パラメータ
            point1 = Point(int(elements[1]), int(elements[2]))
            point2 = Point(int(elements[3]), int(elements[4]))
            distance = int(elements[5])

            # 対象の範囲を定める
            if range_type == "rect":
                r = PointRectRange(point1, point2)
            elif range_type == "distance":
                r = PointDistanceRange(point1, distance)
            else:
                # エラー
                continue
            target_points = [p for p in r.get_list() if p not in calced_points]
            calced_points += target_points

            # 以下、出力する内容について
            output = []
            # 範囲
            for i in range(0, 6):
                output.append(elements[i])
            total = 0
            for e in blocks_info_list:
                ratio = len([p for p in target_points if p in e.points]) / len(e.points)
                total += round(e.block_num * ratio)
            output.append(total)
            output.append(round(total * int(elements[6]) * 0.01))       # 宝石
            for i in range(8, len(elements), 5):
                num = round(total * int(elements[i + 4]) * 0.01)
                if int(elements[i + 2]) >= 0:
                    num = max(num, int(elements[i + 2]))
                if int(elements[i + 3]) >= 0:
                    num = min(num, int(elements[i + 3]))
                output.append(elements[i])  # オブジェクトの種類
                output.append(elements[i + 1])  # オブジェクトのレベル
                output.append(num)          # オブジェクトの個数
            line_text.append(','.join(map(str, output)) + '\n')

    # CSVファイルに書き込み
    with open(output_obj_in_block_default, mode='w', encoding="utf-8") as file:
        for text in line_text:
            file.write(text)

if __name__ == "__main__":
    main()
